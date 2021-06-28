package haxe.ui.backend.raylib;

import haxe.ui.geom.Rectangle;
import RayLib.*;

typedef ScissorEntry = {
    var rect:Rectangle;
}

class ScissorHelper {
    private static var _stack:Array<ScissorEntry> = new Array<ScissorEntry>();
    private static var _pos:Int = 0;
     
    public static function pushScissor(x:Int, y:Int, w:Int, h:Int):Void {
        if (_pos + 1 > _stack.length) {
            _stack.push({
                rect: new Rectangle(),
            });
        }
        var entry = _stack[_pos];
        entry.rect.set(x, y, w, h);
        _pos++;
        
        applyScissor(x, y, w, h);
    }
    
    public static function popScissor():Void {
        _pos--;
        if (_pos == 0) {
            EndScissorMode();
        } else {
            var entry = _stack[_pos - 1];
            applyScissor(Std.int(entry.rect.left), Std.int(entry.rect.top), Std.int(entry.rect.width), Std.int(entry.rect.height));
        }
    }
    
    private static var _cacheRect:Rectangle = new Rectangle();
    private static function applyScissor(x:Int, y:Int, w:Int, h:Int):Void {
        if (_pos > 1) {
            var entry = _stack[_pos - 2];
            _cacheRect.set(x, y, w, h);
            var intersection = entry.rect.intersection(_cacheRect);
            x = Std.int(intersection.left);
            y = Std.int(intersection.top);
            w = Std.int(intersection.width);
            h = Std.int(intersection.height);
            if (x < entry.rect.left) {
                x = Std.int(entry.rect.left);
            }
            if (y < entry.rect.top) {
                y = Std.int(entry.rect.top);
            }
        }
        BeginScissorMode(x, y, w, h);
    }
}    
