package haxe.ui.backend.raylib;

import RayLib.*;
import RayLib.KeyboardKey;
import RayLib.KeyboardKey.*;
import haxe.ui.backend.raylib.KeyboardHelper;
import haxe.ui.backend.raylib.MouseHelper;
import haxe.ui.backend.raylib.StyleHelper;
import haxe.ui.events.KeyboardEvent;
import haxe.ui.events.MouseEvent;
import haxe.ui.util.Timer;
import RayLib.Color;
import RayLib.Colors;

typedef CharPosition = {
    row:Int,
    column:Int
}

typedef CaretInfo = {
    > CharPosition,
    visible:Bool,
    force:Bool,
    timerId:Int
}

typedef SelectionInfo = {
    start:CharPosition,
    end:CharPosition
}

class TextField {
    public static inline var SPACE:Int = 32;
    public static inline var CR:Int = 10;
    public static inline var LF:Int = 13;

    private var _selectionInfo:SelectionInfo = {start: {row: -1, column: -1}, end: {row: -1, column: -1}};
    private var _caretInfo:CaretInfo = {row: -1, column: -1, visible: false, force: false, timerId: -1};

    public function new() {
        textColor = 0x000000;
        caretColor = 0x000000;
        backgroundColor = 0xFFFFFF;
        selectedTextColor = 0xFFFFFF;
        selectedBackgroundColor = 0xFF3390FF;
        
        MouseHelper.notify(MouseEvent.MOUSE_DOWN, onMouseDown);
        
        KeyboardHelper.notify(KeyboardEvent.KEY_DOWN, onKeyDown);
        KeyboardHelper.notify(KeyboardEvent.KEY_PRESS, onKeyPress);
        KeyboardHelper.notify(KeyboardEvent.KEY_UP, onKeyUp);

        recalc();
    }

    //*****************************************************************************************************************//
    // PUBLIC API                                                                                                      //
    //*****************************************************************************************************************//
    public var left:Float = 0;
    public var top:Float = 0;

    public var editable:Bool = true;

    public var textColor:Int;
    public var backgroundColor:Int;
    public var caretColor:Int;

    public var selectedTextColor:Int;
    public var selectedBackgroundColor:Int;

    public var scrollTop:Int = 0;
    public var scrollLeft:Float = 0;

    private var _textChanged:Array<String->Void> = [];
    private var _caretMoved:Array<CharPosition->Void> = [];
    public function notify(textChanged:String->Void, caretMoved:CharPosition->Void) {
        if (textChanged != null) {
            _textChanged.push(textChanged);
        }
        if (caretMoved != null) {
            _caretMoved.push(caretMoved);
        }
    }

    public function remove(textChanged:String->Void, caretMoved:CharPosition->Void) {
        if (textChanged != null) {
            _textChanged.remove(textChanged);
        }
        if (caretMoved != null) {
            _caretMoved.remove(caretMoved);
        }
    }
    
    private function notifyTextChanged() {
        for (l in _textChanged) {
            l(_text);
        }
    }

    private function notifyCaretMoved() {
        for (l in _caretMoved) {
            l(_caretInfo);
        }
    }

    private var _lines:Array<Array<Int>> = null;
    private var _text:String = "";
    public var text(get, set):String;
    private function get_text():String {
        return _text;
    }
    private function set_text(value:String):String {
        if (value == _text) {
            return value;
        }

        if (value == null || value.length == 0) {
            if (isActive == true) {
                _caretInfo.row = 0;
                _caretInfo.column = 0;
            } else {
                _caretInfo.row = -1;
                _caretInfo.column = -1;
            }
            resetSelection();
        }

        _text = value;
        recalc();
        notifyTextChanged();
        return value;
    }

    private var _width:Float = 200;
    public var width(get, set):Float;
    private function get_width():Float {
        return _width;
    }
    private function set_width(value:Float):Float {
        if (value == _width) {
            return value;
        }

        _width = value;
        recalc();
        return value;
    }

    private var _height:Float = 100;
    public var height(get, set):Float;
    private function get_height():Float {
        return _height;
    }
    private function set_height(value:Float):Float {
        if (value == _height) {
            return value;
        }

        _height = value;
        recalc();
        return value;
    }

    private var _password:Bool = false;
    public var password(get, set):Bool;
    private function get_password():Bool {
        return _password;
    }
    private function set_password(value:Bool):Bool {
        if (value == _password) {
            return value;
        }

        _password = value;
        recalc();
        return value;
    }
    
    private var _fontSize:Int = 10;
    public var fontSize(get, set):Int;
    private function get_fontSize():Int {
        return _fontSize;
    }
    private function set_fontSize(value:Int):Int {
        if (value == _fontSize) {
            return value;
        }

        _fontSize = value;
        recalc();
        return value;
    }

    private var _multiline:Bool = true;
    public var multiline(get, set):Bool;
    private function get_multiline():Bool {
        return _multiline;
    }
    private function set_multiline(value:Bool):Bool {
        if (value == _multiline) {
            return value;
        }

        _multiline = value;
        recalc();
        return value;
    }

    private var _wordWrap:Bool = true;
    public var wordWrap(get, set):Bool;
    private function get_wordWrap():Bool {
        return _wordWrap;
    }
    private function set_wordWrap(value:Bool):Bool {
        if (value == _wordWrap) {
            return value;
        }

        _wordWrap = value;
        recalc();
        return value;
    }

    private var _autoHeight:Bool;
    public var autoHeight(get, set):Bool;
    private function get_autoHeight():Bool {
        return _autoHeight;
    }
    private function set_autoHeight(value:Bool):Bool {
        if (value == _autoHeight) {
            return value;
        }

        _autoHeight = value;
        recalc();
        return value;
    }

    public var maxVisibleLines(get, null):Int;
    private inline function get_maxVisibleLines():Int {
        return Math.round(height / fontSize);
    }

    public var numLines(get, null):Int;
    private inline function get_numLines():Int {
        return _lines.length;
    }

    private function resetSelection() {
        _selectionInfo.start.row = -1;
        _selectionInfo.start.column = -1;
        _selectionInfo.end.row = -1;
        _selectionInfo.end.column = -1;
    }

    public var hasSelection(get, null):Bool;
    private function get_hasSelection():Bool {
        return (_selectionInfo.start.row > -1 && _selectionInfo.start.column > -1
                && _selectionInfo.end.row > -1 && _selectionInfo.end.column > -1);
    }

    public var selectionStart(get, null):Int;
    private function get_selectionStart():Int {
        return posToIndex(_selectionInfo.start);
    }

    public var selectionEnd(get, null):Int;
    private function get_selectionEnd():Int {
        return posToIndex(_selectionInfo.end);
    }

    public var caretPosition(get, set):Int;
    private function get_caretPosition():Int {
        return posToIndex(_caretInfo);
    }
    private function set_caretPosition(value:Int):Int {
        var pos = indexToPos(value);
        _caretInfo.row = pos.row;
        _caretInfo.column = pos.column;
        scrollToCaret();
        return value;
    }

    //*****************************************************************************************************************//
    // HELPERS                                                                                                         //
    //*****************************************************************************************************************//
    private static var _currentFocus:TextField;
    public var isActive(get, null):Bool;
    private function get_isActive():Bool {
        return (_currentFocus == this);
    }

    private function recalc() {
        splitLines();
        if (autoHeight == true) {
            height = requiredHeight;
        }
    }

    private function inBounds(x:Float, y:Float):Bool {
        if (x >= left && y >= top && x <= left + width && y <= top + height) {
            return true;
        }
        return false;
    }

    public var requiredWidth(get, null):Float;
    private function get_requiredWidth():Float {
        var rw:Float = 0;
        for (line in _lines) {
            var lineWidth = widthOfCharacters(fontSize, line, 0, line.length);
            if (lineWidth > rw) {
                rw = lineWidth;
            }
        }
        return rw;
    }

    public var requiredHeight(get, null):Float;
    private function get_requiredHeight():Float {
        return _lines.length * fontSize;
    }

    private function moveCaretRight() {
        if (_caretInfo.row >= _lines.length) {
            return;
        }
        if (_caretInfo.column < _lines[_caretInfo.row].length) {
            _caretInfo.column++;
        } else if (_caretInfo.row < _lines.length - 1) {
            _caretInfo.column = 0;
            _caretInfo.row++;
        }
    }

    private function moveCaretLeft() {
        if (_caretInfo.column > 0) {
            _caretInfo.column--;
        } else if (_caretInfo.row > 0) {
            _caretInfo.row--;
            _caretInfo.column = _lines[_caretInfo.row].length;
        }
    }

    private function handleNegativeSelection() {
        if (caretPosition <= selectionStart) {
            _selectionInfo.start.row = _caretInfo.row;
            _selectionInfo.start.column = _caretInfo.column;
        } else {
            _selectionInfo.end.row = _caretInfo.row;
            _selectionInfo.end.column = _caretInfo.column;
        }
    }

    private function handlePositiveSelection() {
        if (caretPosition >= selectionEnd) {
            _selectionInfo.end.row = _caretInfo.row;
            _selectionInfo.end.column = _caretInfo.column;
        } else {
            _selectionInfo.start.row = _caretInfo.row;
            _selectionInfo.start.column = _caretInfo.column;
        }
    }

    private function performKeyOperation(code:Int) {
        var orginalCaretPos:CharPosition = { row: _caretInfo.row, column: _caretInfo.column };
        
        if (code == KEY_ENTER || code == KEY_KP_ENTER) {
            if (multiline) {
                insertText("\n");
            }
        } else if (code == KEY_LEFT) {
            moveCaretLeft();

            if (_ctrl) {
                while((_caretInfo.column > 0 || _caretInfo.row > 0) && _text.charCodeAt(posToIndex(_caretInfo)-1) == SPACE) {
                    moveCaretLeft();
                }
                while((_caretInfo.column > 0 || _caretInfo.row > 0) && _text.charCodeAt(posToIndex(_caretInfo)-1) != SPACE) {
                    moveCaretLeft();
                }
            }

            scrollToCaret();

            if (_shift == true) {
                handleNegativeSelection();
            } else {
                resetSelection();
            }
        } else if (code == KEY_RIGHT) {
            moveCaretRight();

            if (_ctrl) {
                while((_caretInfo.column < _lines[_caretInfo.row].length && _caretInfo.row < _lines.length) && _text.charCodeAt(posToIndex(_caretInfo)) != SPACE) {
                    moveCaretRight();
                }
                while((_caretInfo.column < _lines[_caretInfo.row].length && _caretInfo.row < _lines.length) && _text.charCodeAt(posToIndex(_caretInfo)) == SPACE) {
                    moveCaretRight();
                }
            }

            scrollToCaret();

            if (_shift == true) {
                handlePositiveSelection();
            } else {
                resetSelection();
            }
        } else if (code == KEY_UP) {
            if (_caretInfo.row > 0) {
                _caretInfo.column = findClosestColumn(_caretInfo, -1);
                _caretInfo.row--;
            }
            scrollToCaret();

            if (_shift == true) {
                handleNegativeSelection();
            } else {
                resetSelection();
            }
        } else if (code == KEY_DOWN) {
            if (_caretInfo.row < _lines.length - 1) {
                _caretInfo.column = findClosestColumn(_caretInfo, 1);
                _caretInfo.row++;
            }
            scrollToCaret();

            if (_shift == true) {
                handlePositiveSelection();
            } else {
                resetSelection();
            }
        } else if (code == KEY_BACKSPACE) {
            if (hasSelection) {
                insertText("");
            } else {
                if (_ctrl) {
                    var caretIndex = posToIndex(_caretInfo);
                    var caretDisplacement = 0;
                    while (caretIndex+caretDisplacement > 0 && _text.charCodeAt(caretIndex+caretDisplacement-1) == SPACE)
                        caretDisplacement--;
                    while (caretIndex+caretDisplacement > 0 && _text.charCodeAt(caretIndex+caretDisplacement-1) != SPACE)
                        caretDisplacement--;

                    deleteCharsFromCaret(caretDisplacement);
                    scrollToCaret();
                } else {
                    deleteCharsFromCaret(-1);
                }
            }
        } else if (code == KEY_DELETE) {
            if (hasSelection) {
                insertText("");
            } else {
                if (_ctrl) {
                    // Delete until the start of the next word
                    var caretIndex = posToIndex(_caretInfo);
                    var caretDisplacement = 0;
                    while (_text.charCodeAt(caretIndex+caretDisplacement) != SPACE && caretIndex+caretDisplacement < _text.length)
                        caretDisplacement++;
                    while (_text.charCodeAt(caretIndex+caretDisplacement) == SPACE && caretIndex+caretDisplacement < _text.length)
                        caretDisplacement++;

                    deleteCharsFromCaret(caretDisplacement, false);
                    caretPosition = caretIndex; // Updates _caretInfo (text changes may alter row/column, for instance after wrapping)
                    scrollToCaret();

                } else {
                    deleteCharsFromCaret(1, false);
                }
            }
        } else if (code == KEY_HOME) {
            scrollLeft = 0;
            _caretInfo.column = 0;
            scrollToCaret();

            if (_shift == true) {
                handleNegativeSelection();
            } else {
                resetSelection();
            }
        } else if (code == KEY_END) {
            var line = _lines[_caretInfo.row];
            scrollLeft = widthOfCharacters(fontSize, line, 0, line.length) - width + caretWidth;
            if (scrollLeft < 0) {
                scrollLeft = 0;
            }
            _caretInfo.column = line.length;
            scrollToCaret();

            if (_shift == true) {
                handlePositiveSelection();
            } else {
                resetSelection();
            }
        } else if (code == KEY_A) {
            if (_ctrl) {
                _selectionInfo.start.row = 0;
                _selectionInfo.start.column = 0;
                
                var line = _lines[_lines.length-1];
                
                _caretInfo.row = _lines.length-1;
                _caretInfo.column = line.length;
                _selectionInfo.end.row = _lines.length-1;
                _selectionInfo.end.column = line.length;
                scrollToCaret();
            }
        } else if (code == KEY_C) {
            if (_ctrl) {
                SetClipboardText(onCopy());
            }
        } else if (code == KEY_X) {
            if (_ctrl) {
                SetClipboardText(onCut());
            }
        } else if (code == KEY_V) {
            if (_ctrl) {
                onPaste(GetClipboardText());
            }
        }
        
        if (_caretInfo.row != orginalCaretPos.row || _caretInfo.column != orginalCaretPos.column) {
           notifyCaretMoved();
        }
    }
    
    private function insertText(s:String) {
        var start:CharPosition = _caretInfo;
        var end:CharPosition = _caretInfo;
        if (_selectionInfo.start.row != -1 && _selectionInfo.start.column != -1) {
            start = _selectionInfo.start;
        }
        if (_selectionInfo.end.row != -1 && _selectionInfo.end.column != -1) {
            end = _selectionInfo.end;
        }


        var startIndex = posToIndex(start);
        var endIndex = posToIndex(end);

        var before = text.substring(0, startIndex);
        var after = text.substring(endIndex, text.length);

        text = before + s + after;
        var delta = s.length - (endIndex - startIndex);

        caretPosition = endIndex + delta;
        notifyCaretMoved();
        scrollToCaret();

        Timer.delay(function () {
            caretPosition = endIndex + delta;
            notifyCaretMoved();
            scrollToCaret();
        }, 10);
        
        
        resetSelection();
    }

    private var caretLeft(get, null):Float;
    private function get_caretLeft():Float {
        var line = _lines[_caretInfo.row];
        var xpos:Float = left - scrollLeft;
        if (line == null) {
            return xpos;
        }
        return xpos + widthOfCharacters(fontSize, line, 0, _caretInfo.column);
    }

    private var caretTop(get, null):Float;
    private function get_caretTop():Float {
        var ypos:Float = top;
        return ypos + ((_caretInfo.row - scrollTop) * fontSize);
    }

    private var caretWidth(get, null):Float;
    private function get_caretWidth():Float {
        return 1;
    }

    private var caretHeight(get, null):Float;
    private function get_caretHeight():Float {
        return fontSize;
    }

    //*****************************************************************************************************************//
    // EVENTS                                                                                                          //
    //*****************************************************************************************************************//
    private var _downKey:Int = 0;
    private var _shift:Bool = false;
    private var _ctrl:Bool = false;
    
    private function onCut() {
        if (hasSelection) {
            var cutText = _text.substring(posToIndex(_selectionInfo.start), posToIndex(_selectionInfo.end));
            insertText("");
            return cutText;
        }

        return "";
    }

    private function onCopy() {
        if (hasSelection) {
            return _text.substring(posToIndex(_selectionInfo.start), posToIndex(_selectionInfo.end));
        }

        return "";
    }
    
    private function onPaste(text:String) {
        insertText(text);
    }
    
    private var _repeatTimer:Timer = null;
    private var _repeatTimer2:Timer = null;
    private function onKeyDown(event:KeyboardEvent) {
        if (event.keyCode == 0) {
            return;
        }
        
        if (isActive == false) {
            return;
        }
        
        var character = String.fromCharCode(event.data);
        if ((character.charCodeAt(0) == CR || character.charCodeAt(0) == LF) && multiline == false) {
            return;
        }
        
        if (event.keyCode == KeyboardKey.KEY_LEFT_SHIFT || event.keyCode == KeyboardKey.KEY_RIGHT_SHIFT) {
            if (!hasSelection) {
                _selectionInfo.start.row = _caretInfo.row;
                _selectionInfo.start.column = _caretInfo.column;
                _selectionInfo.end.row = _caretInfo.row;
                _selectionInfo.end.column = _caretInfo.column;
            }
            _shift = true;
        } else if (event.keyCode == KeyboardKey.KEY_LEFT_CONTROL || event.keyCode == KeyboardKey.KEY_RIGHT_CONTROL) {
            _ctrl = true;
        }

        _downKey = event.keyCode;
        _caretInfo.force = true;
        _caretInfo.visible = true;

        performKeyOperation(event.keyCode);
        
        if (_repeatTimer != null) {
            _repeatTimer.stop();
            _repeatTimer = null;
        }

        if (_repeatTimer2 != null) {
            _repeatTimer2.stop();
            _repeatTimer2 = null;
        }
        
        _repeatTimer = new Timer(500, function() {
            if (_repeatTimer2 != null) {
                _repeatTimer2.stop();
                _repeatTimer2 = null;
            }
            if (_downKey != 0) {
                _repeatTimer2 = new Timer(33, function() {
                    onKeyRepeat();
                });
            }
        });
    }

    private function onKeyRepeat() {
        if (_downKey != 0) {
            performKeyOperation(_downKey);
        }
    }
    
    private function onKeyPress(event:KeyboardEvent) {
        if (isActive == false) {
            return;
        }

        var character = String.fromCharCode(event.data);
        if ((character.charCodeAt(0) == CR || character.charCodeAt(0) == LF) && multiline == false) {
            return;
        }

        if (event.data != 0) {
            insertText(character);
        }

        _caretInfo.force = false;
        _caretInfo.visible = true;
        _downKey = 0;
        
        if (_repeatTimer != null) {
            _repeatTimer.stop();
            _repeatTimer = null;
        }
        if (_repeatTimer2 != null) {
            _repeatTimer2.stop();
            _repeatTimer2 = null;
        }
    }

    private function onKeyUp(event:KeyboardEvent) {
        if (isActive == false) {
            return;
        }

        if (event.keyCode == KeyboardKey.KEY_LEFT_SHIFT || event.keyCode == KeyboardKey.KEY_RIGHT_SHIFT) {
            _shift = false;
        } else if (event.keyCode == KeyboardKey.KEY_LEFT_CONTROL || event.keyCode == KeyboardKey.KEY_RIGHT_CONTROL) {
            _ctrl = false;
        }
        
        _caretInfo.force = false;
        _caretInfo.visible = true;
        _downKey = 0;
        
        if (_repeatTimer != null) {
            _repeatTimer.stop();
            _repeatTimer = null;
        }
        if (_repeatTimer2 != null) {
            _repeatTimer2.stop();
            _repeatTimer2 = null;
        }
    }
    
    private function onMouseDown(event:MouseEvent) {
        var button:Int = event.data;
        var x = event.screenX;
        var y = event.screenY;
        
        if (inBounds(x, y) == false) {
            return;
        }

        if (_currentFocus != null && _currentFocus != this) {
            _currentFocus.onBlur();
        }
        _currentFocus = this;

        var localX = x - left + scrollLeft;
        var localY = y - top;

        resetSelection();

        _caretInfo.row = scrollTop + Std.int(localY / fontSize);
        if (_caretInfo.row > _lines.length - 1) {
            _caretInfo.row = _lines.length - 1;
        }
        var line = _lines[_caretInfo.row];
        if (line == null) {
            return;
        }
        var totalWidth:Float = 0;
        var i = 0;
        var inText = false;
        for (ch in line) {
            var charWidth = widthOfCharacters(fontSize, [ch], 0, 1);
            if (totalWidth + charWidth > localX) {
                _caretInfo.column = i;
                var delta = localX - totalWidth;
                if (delta > charWidth * 0.6) {
                    _caretInfo.column++;
                }
                inText = true;
                break;
            } else {
                totalWidth += charWidth;
            }
            i++;
        }

        if (inText == false) {
            _caretInfo.column = line.length;
        }

        scrollToCaret();
        _currentFocus.onFocus();
    }

    public function focus() {
        onFocus();
    }
    
    private var _focusTimer:Timer = null;
    private function onFocus() {
        if (_focusTimer == null) {
            _focusTimer = new Timer(400, function() {
                _caretInfo.visible = !_caretInfo.visible;
            });
        }
        
        _caretInfo.visible = true;
    }

    public function blur() {
        onBlur();
    }
    
    private function onBlur() {
        if (_focusTimer != null) {
            _focusTimer.stop();
            _focusTimer = null;
        }
        _caretInfo.timerId = -1;
        _caretInfo.visible = false;
    }

    //*****************************************************************************************************************//
    // UTIL                                                                                                            //
    //*****************************************************************************************************************//
    private function widthOfCharacters(fontSize:Int, characters:Array<Int>, start:Int, length:Int):Int {
        var width = 0;
        
        for (i in start...start + length) {
            width += MeasureText(String.fromCharCode(characters[i]), fontSize) + 1;
        }
        
        if (width > 0) {
            //width -= 1;
        }
        
        return width;
    }
    
    private function splitLines() {
        _lines = [];

        if (text == null) {
            return;
        }

        if (multiline == false) {
            var text = text.split("\n").join("").split("\r").join("");
            if (password == true) {
                var passwordText = "";
                for (i in 0...text.length) {
                    passwordText += "*";
                }
                text = passwordText;
            }
            _lines.push(StringExtensions.toCharArray(text));
        } else if (wordWrap == false) {
            var arr = StringTools.replace(StringTools.replace(text, "\r\n", "\n"), "\r", "\n").split("\n");
            for (a in arr) {
                _lines.push(StringExtensions.toCharArray(a));
            }
        } else if (wordWrap == true) {
            var totalWidth:Float = 0;
            var spaceIndex:Int = -1;
            var start = 0;
            for (i in 0...text.length) {
                var charCode = text.charCodeAt(i);
                if (charCode == SPACE) {
                    spaceIndex = i;
                } else if (charCode == CR || charCode == LF) {
                    _lines.push(StringExtensions.toCharArray(text.substring(start, i)));
                    start = i + 1;
                    totalWidth = 0;
                    spaceIndex = -1;
                    continue;
                }

                var charWidth = widthOfCharacters(fontSize, [charCode], 0, 1);
                if (totalWidth + charWidth > width - 0) { // TODO: magic number
                    _lines.push(StringExtensions.toCharArray(text.substring(start, spaceIndex)));
                    start = spaceIndex + 1;
                    var remain = StringExtensions.toCharArray(text.substring(spaceIndex + 1, i + 1));
                    totalWidth = widthOfCharacters(fontSize, remain, 0, remain.length);
                } else {
                    totalWidth += charWidth;
                }
            }

            if (start < text.length) {
                _lines.push(StringExtensions.toCharArray(text.substring(start, text.length)));
            }
        }
    }

    private function deleteCharsFromCaret(count:Int = 1, moveCaret:Bool = true) {
        deleteChars(count, _caretInfo, moveCaret);
    }

    private function deleteChars(count:Int, from:CharPosition, moveCaret:Bool = true) {
        var fromIndex = posToIndex(from);
        var toIndex = fromIndex + count;

        var startIndex = fromIndex;
        var endIndex = toIndex;
        if (startIndex > endIndex) {
            startIndex = toIndex;
            endIndex = fromIndex;
        }

        if (endIndex > text.length)
            endIndex = text.length;

        var before = text.substring(0, startIndex);
        var after = text.substring(endIndex, text.length);

        text = before + after;
        if (moveCaret == true) {
            caretPosition = endIndex + count;
        }
    }

    private function posToIndex(pos:CharPosition) {
        var index = 0;
        var i = 0;
        for (line in _lines) {
            if (i == pos.row) {
                var column = pos.column;
                if (line.length < pos.column) {
                    column = line.length-1;
                }
                index += column;
                break;
            } else {
                index += line.length + 1;
            }
            i++;
        }

        return index;
    }

    private function indexToPos(index:Int):CharPosition {
        var pos:CharPosition = { row: 0, column: 0 };

        var count:Int = 0;
        for (line in _lines) {
            if (index <= line.length) {
                pos.column = index;
                break;
            } else {
                index -= (line.length + 1);
                pos.row++;
            }
        }

        return pos;
    }

    private function scrollToCaret() {
        ensureRowVisible(_caretInfo.row);

        if (_lines.length < maxVisibleLines) {
            scrollTop = 0;
        }

        var line = _lines[_caretInfo.row];
        if (caretLeft - left > width) {
            scrollLeft += caretLeft - left - width + 50;

            if (scrollLeft + width > widthOfCharacters(fontSize, line, 0, line.length)) {
                scrollLeft = widthOfCharacters(fontSize, line, 0, line.length) - width + caretWidth;
                if (scrollLeft < 0) {
                    scrollLeft = 0;
                }
            }
        } else if (caretLeft - left < 0) {
            scrollLeft += (caretLeft - left) - 50;

            if (scrollLeft < 0 || widthOfCharacters(fontSize, line, 0, line.length) <= width) {
                scrollLeft = 0;
            }
        }
    }

    private function ensureRowVisible(row:Int) {
        if (row >= scrollTop && row <= scrollTop + maxVisibleLines - 1) {
            return;
        }

        if (row < scrollTop + maxVisibleLines) {
            scrollTop = row;
        } else {
            scrollTop = row - maxVisibleLines + 1;
        }
    }

    private function findClosestColumn(origin:CharPosition, offset:Int) {
        var closestColumn = origin.column;
        var offsetLine = _lines[origin.row + offset];
        if (closestColumn > offsetLine.length) {
            closestColumn = offsetLine.length;
        }
        return closestColumn;
    }

    //*****************************************************************************************************************//
    // RENDER                                                                                                          //
    //*****************************************************************************************************************//
    private function drawCharacters(characters:Array<Int>, start:Int, length:Int, x:Int, y:Int, color:Int) {
        var s = "";
        for (i in start...start + length) {
            s += String.fromCharCode(characters[i]);
        }
        
        DrawText(s, x, y, fontSize, StyleHelper.col(color));
    }
    
    public function draw() {
        var x = Std.int(left);
        var y = Std.int(top);
        var w = Std.int(width);
        var h = Std.int(height);
        DrawRectangle(x, y, w, h, StyleHelper.col(backgroundColor));
        
        ScissorHelper.pushScissor(Math.round(x), Math.round(y), Math.round(w), Math.round(h));
        
        var xpos:Int = Std.int(x - scrollLeft);
        var ypos:Int = y;
        
        var start = scrollTop;
        var end = start + maxVisibleLines;

        if (start > 0) {
            start--; // show one less line so it looks nicer
            ypos -= fontSize;
        }
        if (end > _lines.length) {
            end = _lines.length;
        }
        if (end < _lines.length) {
            end++; // show one additonal line so it looks nicer
        }
        
        for (i in start...end) {
            xpos = Std.int(x - scrollLeft);
            var line = _lines[i];
            
            if (i >= _selectionInfo.start.row && i <= _selectionInfo.end.row) {
                if (i == _selectionInfo.start.row && _selectionInfo.start.row == _selectionInfo.end.row) {
                    drawCharacters(line, 0, _selectionInfo.start.column, xpos, ypos, textColor);
                    xpos += widthOfCharacters(fontSize, line, 0, _selectionInfo.start.column);
                    
                    DrawRectangle(xpos, ypos, widthOfCharacters(fontSize, line, _selectionInfo.start.column, (_selectionInfo.end.column) - (_selectionInfo.start.column)), fontSize, StyleHelper.col(selectedBackgroundColor));
                    
                    drawCharacters(line, _selectionInfo.start.column, (_selectionInfo.end.column) - (_selectionInfo.start.column), xpos, ypos, selectedTextColor);
                    xpos += widthOfCharacters(fontSize, line, _selectionInfo.start.column, (_selectionInfo.end.column) - (_selectionInfo.start.column));
                    
                    drawCharacters(line, _selectionInfo.end.column, line.length, xpos, ypos, textColor);
                } else if (i == _selectionInfo.start.row && _selectionInfo.start.row != _selectionInfo.end.row) {
                    drawCharacters(line, 0, _selectionInfo.start.column, xpos, ypos, textColor);
                    xpos += widthOfCharacters(fontSize, line, 0, _selectionInfo.start.column);
                    
                    DrawRectangle(xpos, ypos, widthOfCharacters(fontSize, line, _selectionInfo.start.column, line.length - (_selectionInfo.start.column)), fontSize, StyleHelper.col(selectedBackgroundColor));
                    
                    drawCharacters(line, _selectionInfo.start.column, line.length - (_selectionInfo.start.column), xpos, ypos, selectedTextColor);
                } else if (i == _selectionInfo.end.row && _selectionInfo.start.row != _selectionInfo.end.row) {
                    DrawRectangle(xpos, ypos, widthOfCharacters(fontSize, line, 0, _selectionInfo.end.column), fontSize, StyleHelper.col(selectedBackgroundColor));
                    
                    drawCharacters(line, 0, _selectionInfo.end.column, xpos, ypos, selectedTextColor);
                    xpos += widthOfCharacters(fontSize, line, 0, _selectionInfo.end.column);
                    
                    drawCharacters(line, _selectionInfo.end.column, line.length - (_selectionInfo.end.column), xpos, ypos, textColor);
                } else {
                    DrawRectangle(xpos, ypos, widthOfCharacters(fontSize, line, 0, line.length), fontSize, StyleHelper.col(selectedBackgroundColor));
                    
                    drawCharacters(line, 0, line.length, xpos, ypos, selectedTextColor);
                }
            } else {
                drawCharacters(line, 0, line.length, xpos, ypos, textColor);
            }
            
            ypos += fontSize;
        }
        
        if (_caretInfo.row > -1 && _caretInfo.column > -1 && (_caretInfo.visible == true || _caretInfo.force == true)) {
            DrawRectangle(Std.int(caretLeft), Std.int(caretTop), Std.int(caretWidth), Std.int(caretHeight), StyleHelper.col(textColor));
        }
        
        ScissorHelper.popScissor();
    }
}
