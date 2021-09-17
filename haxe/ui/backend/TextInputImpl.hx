package haxe.ui.backend;

import haxe.ui.backend.raylib.TextField;
import RayLib.*;

class TextInputImpl extends TextBase {
    private var _tf:TextField;

    private var _textAlign:String;
    private var _fontSize:Float = 10;
    private var _fontName:String;
    private var _color:Int = -1;
    private var _backgroundColor:Int = -1;
    
    public function new() {
        super();
        _tf = new TextField();
        _tf.notify(onTextChanged, onCaretMoved);
    }

    public override function focus() {
        _tf.focus();
    }
    
    public override function blur() {
        _tf.blur();
    }
    
    private function onTextChanged(text) {
        _text = text;
        measureText();
        if (_inputData.onChangedCallback != null) {
            _inputData.onChangedCallback();
        }
    }
    
    private function onCaretMoved(pos) {
        _inputData.hscrollPos = _tf.scrollLeft;
        _inputData.vscrollPos = _tf.scrollTop;
        if (_inputData.onScrollCallback != null) {
            _inputData.onScrollCallback();
        }
    }
    
    private override function validateData() {
        if (_text != null) {
            _tf.text = normalizeText(_text);
        }
        
        _tf.scrollLeft = _inputData.hscrollPos;
        _tf.scrollTop = Std.int(_inputData.vscrollPos);
    }
    
    private override  function validateStyle():Bool {
        var measureTextRequired:Bool = false;
        
        if (_textStyle != null) {
            _tf.multiline = _displayData.multiline;
            if (_tf.multiline == true) {
                offset = 4;
                measureTextRequired = true;
            }
            _tf.wordWrap = _displayData.wordWrap;
            _tf.password = _inputData.password;
            
            if (_textAlign != _textStyle.textAlign) {
                _textAlign = _textStyle.textAlign;
            }
            
            if (_textStyle.fontSize != null && _fontSize != _textStyle.fontSize) {
                _fontSize = _textStyle.fontSize;
                _tf.fontSize = Std.int(_fontSize);
                measureTextRequired = true;
            }
            
            if (_fontName != _textStyle.fontName && _fontInfo != null) {
                _fontName = _textStyle.fontName;
                measureTextRequired = true;
            }
            
            if (_textStyle.color != null && _color != _textStyle.color) {
                _color = _textStyle.color;
                _tf.textColor = _textStyle.color;
            }
            
            if (_textStyle.backgroundColor != null && _backgroundColor != _textStyle.backgroundColor) {
                _backgroundColor = _textStyle.backgroundColor;
                _tf.backgroundColor = _textStyle.backgroundColor;
            }
            
        }
        
        return measureTextRequired;
    }
    
    private var offset:Int = 0;
    private override function validateDisplay() {
        if (_width > 0) {
            _tf.width = _width - offset;
        }
        if (_height > 0) {
            _tf.ensureRowVisible(0);
            _tf.height = _height - offset;
        }
    }

    public function draw(x:Float, y:Float) {
        _tf.left = x + _left + (offset / 2);
        _tf.top = y + _top + (offset / 2);
        _tf.draw();
    }
    
    private override function measureText() {
        if (_text == null || _text.length == 0) {
            _textWidth = 0;
            _textHeight = _fontSize;
            return;
        }

        if (_width <= 0) {
            _textWidth = MeasureText(_text, Std.int(_fontSize));
            _textHeight = _fontSize;
            return;
        }

        _tf.width = _width - offset;
        _textWidth = _tf.requiredWidth;
        _textHeight = _tf.requiredHeight;

        if (_textHeight <= 0) {
            _textHeight = Std.int(_fontSize);
        }
        
        _inputData.hscrollMax = _tf.requiredWidth - _tf.width;
        _inputData.hscrollPageSize = (_tf.width * _inputData.hscrollMax) / _tf.requiredWidth;
        
        _inputData.vscrollMax = _tf.numLines - _tf.maxVisibleLines;
        _inputData.vscrollPageSize = (_tf.maxVisibleLines * _inputData.vscrollMax) / _tf.numLines;
        _inputData.vscrollPageStep = 1;
    }
    
    private function normalizeText(text:String):String {
        text = StringTools.replace(text, "\\n", "\n");
        return text;
    }
}
