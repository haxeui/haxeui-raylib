package haxe.ui.backend;

import RayLib.*;
import haxe.ui.backend.raylib.StyleHelper;

class TextDisplayImpl extends TextBase {
    private var _textAlign:String;
    private var _fontSize:Int = 10;
    private var _fontSpacing:Int = 1;
    private var _fontName:String;
    private var _color:Int;
    
    private override function validateData() {
        if (_text != null) {
            if (_dataSource == null) {
                _text = normalizeText(_text);
            }
        }
    }
    
    private override function validateStyle():Bool {
        if (_textStyle != null) {
            if (_textAlign != _textStyle.textAlign) {
                _textAlign = _textStyle.textAlign;
            }
            
            if (_color != _textStyle.color) {
                _color = _textStyle.color;
            }
        }
        return true;
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
        if (_text == null || _text.length == 0 ) {
            _textWidth = 0;
            _textHeight = 0;
            return;
        }

        if (_width <= 0) {
            _lines = new Array<String>();
            _lines.push(_text);
            _textWidth = MeasureText(_text, _fontSize);
            _textHeight = _fontSize;
            return;
        }


        var maxWidth:Float = _width * Toolkit.scale;
        _lines = new Array<String>();
        _text = normalizeText(_text);
        var lines = _text.split("\n");
        var biggestWidth:Float = 0;
        for (line in lines) {
            var tw = MeasureText(line, _fontSize);
            if (tw > maxWidth) {
                var words = Lambda.list(line.split(" "));
                while (!words.isEmpty()) {
                    line = words.pop();
                    tw = MeasureText(line, _fontSize);
                    biggestWidth = Math.max(biggestWidth, tw);
                    var nextWord = words.pop();
                    while (nextWord != null && (tw = MeasureText(line + " " + nextWord, _fontSize)) <= maxWidth) {
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
        
        _textWidth = Math.round(_textWidth + 1);
        _textHeight = Math.round(_textHeight);
        
        if (_textWidth % 2 != 0) {
            _textWidth++;
        }
        if (_textHeight % 2 != 0) {
            _textHeight++;
        }
    }
    
    public function draw(x:Int, y:Int) {
        if (_lines != null) {
            var ty:Float = y + _top;
            for (line in _lines) {
                var tx:Float = x;
                var lx:Int = MeasureText(line, _fontSize);
            
                switch(_textAlign) {
                    case "center":
                        tx += ((_width - lx) * Toolkit.scale) / 2;

                    case "right":
                        tx += (_width - lx) * Toolkit.scale;

                    default:
                        tx += _left;
                }

                DrawText(line, Std.int(tx), Std.int(ty), _fontSize, StyleHelper.col(_color));
                ty += _fontSize;
            }
        }
    }
    
    private function normalizeText(text:String):String {
        text = StringTools.replace(text, "\\n", "\n");
        return text;
    }
}
