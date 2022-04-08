package haxe.ui.backend;

import RayLib.*;
import RayLib.Font;
import RayLib.Vector2;
import haxe.ui.backend.raylib.FontHelper;
import haxe.ui.backend.raylib.StyleHelper;

// might want to port this: https://github.com/mattdesl/word-wrapper/blob/master/index.js

class TextDisplayImpl extends TextBase {
    private var _textAlign:String;
    private var _fontSize:Int = 10;
    private var _fontName:String;
    private var _color:Int;
    private var _currentFontName:String = "default";
    private var _currentFont:Font;
    
    public function new() {
        super();
        _currentFont = FontHelper.getFont(_currentFontName);
    }
    
    private override function validateData() {
        if (_text != null) {
            if (_dataSource == null) {
                _text = normalizeText(_text);
            }
        }
    }
    
    private override function validateStyle():Bool {
        var measureTextRequired:Bool = false;
        
        if (_textStyle != null) {
            if (_textAlign != _textStyle.textAlign) {
                _textAlign = _textStyle.textAlign;
                measureTextRequired = true;
            }
            
            if (_textStyle.color != null && _color != _textStyle.color) {
                _color = _textStyle.color;
            }
            
            if (_textStyle.fontSize != null && _fontSize != _textStyle.fontSize) {
                _fontSize = Std.int(_textStyle.fontSize);
                measureTextRequired = true;
            }
            
            if (_textStyle.fontName != null && _textStyle.fontName != _currentFontName && this._fontInfo != null && this._fontInfo.data != null) {
                _currentFontName = _textStyle.fontName;
                if (StringTools.endsWith(_currentFontName, ".ttf")) {
                    _currentFont = FontHelper.loadTtfFont(_currentFontName, _fontSize);
                } else {
                    _currentFont = this._fontInfo.data;
                }
                measureTextRequired = true;
            }
        }
        
        return measureTextRequired;
    }
    
    private override function validateDisplay() {
        if (_width == 0 && _textWidth > 0) {
            _width = _textWidth;
        }
        if (_height == 0 && _textHeight > 0) {
            _height = _textHeight;
        }
    }

    private var _lines:Array<String>;
    private override function measureText() {
        measureTextBreakWords();
        
        var maxWidth:Float = _width * Toolkit.scale;
        if (_width > 0 && _textWidth > maxWidth) {
            measureTextBreakAny();
        }
        
        _textWidth = Math.round(_textWidth + 1);
        _textHeight = Math.round(_textHeight - 1);
        
        if (_textWidth % 2 != 0) {
            _textWidth++;
        }
        if (_textHeight % 2 != 0) {
            //_textHeight++;
        }
    }
    
    private function measureTextBreakAny() {
        if (_text == null || _text.length == 0 ) {
            _textWidth = 0;
            _textHeight = 0;
            return;
        }

        var spacing = Std.int(_fontSize / _currentFont.baseSize);
        
        if (_width <= 0) {
            _lines = new Array<String>();
            _lines.push(_text);
            _textWidth = Std.int(MeasureTextEx(_currentFont, _text, _fontSize, spacing).x);
            _textHeight = _fontSize;
            return;
        }
        
        var maxWidth:Float = _width * Toolkit.scale;
        _lines = new Array<String>();
        _text = normalizeText(_text);
        var lines = _text.split("\n");
        var biggestWidth:Float = 0;
        for (line in lines) {
            var tw = Std.int(MeasureTextEx(_currentFont, line, _fontSize, spacing).x);
            if (tw > maxWidth) {
                var words = Lambda.list(line.split(""));
                while (!words.isEmpty()) {
                    line = words.pop();
                    tw = Std.int(MeasureTextEx(_currentFont, line, _fontSize, spacing).x);
                    biggestWidth = Math.max(biggestWidth, tw);
                    var nextWord = words.pop();
                    while (nextWord != null && (tw = Std.int(MeasureTextEx(_currentFont, line + " " + nextWord, _fontSize, spacing).x)) <= maxWidth) {
                        biggestWidth = Math.max(biggestWidth, tw);
                        line += "" + nextWord;
                        nextWord = words.pop();
                    }
                    _lines.push(line);
                    if (nextWord != null) {
                        words.push(nextWord);
                    }
                }
            } else {
                biggestWidth = Math.max(biggestWidth, tw);
                if (line != '') {
                    _lines.push(line);
                }
            }
        }

        _textWidth = biggestWidth / Toolkit.scale;
        _textHeight = (_fontSize * _lines.length) / Toolkit.scale;
    }
    
    private function measureTextBreakWords() {
        if (_text == null || _text.length == 0 ) {
            _textWidth = 0;
            _textHeight = 0;
            return;
        }

        var spacing = Std.int(_fontSize / _currentFont.baseSize);
        
        if (_width <= 0) {
            _lines = new Array<String>();
            _lines.push(_text);
            _textWidth = Std.int(MeasureTextEx(_currentFont, _text, _fontSize, spacing).x);
            _textHeight = _fontSize;
            return;
        }

        var maxWidth:Float = _width * Toolkit.scale;
        _lines = new Array<String>();
        _text = normalizeText(_text);
        var lines = _text.split("\n");
        var biggestWidth:Float = 0;
        for (line in lines) {
            var tw = Std.int(MeasureTextEx(_currentFont, line, _fontSize, spacing).x);
            if (tw > maxWidth) {
                var words = Lambda.list(line.split(" "));
                while (!words.isEmpty()) {
                    line = words.pop();
                    tw = Std.int(MeasureTextEx(_currentFont, line, _fontSize, spacing).x);
                    biggestWidth = Math.max(biggestWidth, tw);
                    var nextWord = words.pop();
                    //while (nextWord != null && (tw = MeasureText(line + " " + nextWord, _fontSize)) <= maxWidth) {
                    while (nextWord != null && (tw = Std.int(MeasureTextEx(_currentFont, line + " " + nextWord, _fontSize, spacing).x)) <= maxWidth) {
                        biggestWidth = Math.max(biggestWidth, tw);
                        line += " " + nextWord;
                        nextWord = words.pop();
                    }
                    _lines.push(line);
                    if (nextWord != null) {
                        words.push(nextWord);
                    }
                }
            } else {
                biggestWidth = Math.max(biggestWidth, tw);
                if (line != '') {
                    _lines.push(line);
                }
            }
        }

        _textWidth = biggestWidth / Toolkit.scale;
        _textHeight = (_fontSize * _lines.length) / Toolkit.scale;
        
    }
    
    public function draw(x:Int, y:Int) {
        if (_lines != null) {
            var spacing = Std.int(_fontSize / _currentFont.baseSize);
            var ty:Float = y + _top;
            for (line in _lines) {
                var tx:Float = x;
                var lx:Int = Std.int(MeasureTextEx(_currentFont, line, _fontSize, spacing).x);
            
                switch(_textAlign) {
                    case "center":
                        tx += ((_width - lx) * Toolkit.scale) / 2;

                    case "right":
                        tx += (_width - lx) * Toolkit.scale;

                    default:
                        tx += _left;
                }

                //DrawText(line, Std.int(tx), Std.int(ty), _fontSize, StyleHelper.col(_color));
                DrawTextEx(_currentFont, line, Vector2.create(Std.int(tx), Std.int(ty)), _fontSize, spacing, StyleHelper.col(_color));
                ty += _fontSize;
            }
        }
    }
    
    private function normalizeText(text:String):String {
        text = StringTools.replace(text, "\\n", "\n");
        return text;
    }
}
