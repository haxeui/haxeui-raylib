package haxe.ui.backend.raylib;

import RayLib.*;
import RayLib.Font;
import cpp.NativeArray;
import haxe.io.Bytes;

class FontHelper {
    private static var _fonts:Map<String, Font> = new Map<String, Font>();

    private static var _init:Bool = false;
    private static function init() {
        if (_init == true) {
            return;
        }
        
        _init = true;
        
        _fonts.set("default", GetFontDefault());
    }
    
    public static function getFont(id:String) {
        init();
        if (_fonts.exists(id) == false) {
            return null;
        }
        var f = _fonts.get(id);
        return f;
    }
    
    public static function setFont(id:String, font:Font) {
        init();
        _fonts.set(id, font);
    }
    
    public static function hasFont(id:String) {
        init();
        return _fonts.exists(id);
    }
    
    public static function setTtfFont(id:String, size:Int, font:Font) {
        init();
        var key = id + "_" + size;
        _fonts.set(key, font);
    }
    
    public static function getTtfFont(id:String, size:Int) {
        init();
        var key = id + "_" + size;
        return _fonts.get(key);
    }
    
    public static function hasTtfFont(id:String, size:Int) {
        init();
        var key = id + "_" + size;
        return _fonts.exists(key);
    }
    
    public static function loadTtfFont(resourceId:String, size:Int) {
        if (hasTtfFont(resourceId, size)) {
            return getTtfFont(resourceId, size);
        }
        var bytes:Bytes = Resource.getBytes(resourceId);
        var p = NativeArray.address(bytes.getData(), 0).constRaw;
        var font = LoadFontFromMemory(".ttf", p, bytes.length, 30, null, 255);
        setTtfFont(resourceId, size, font);
        return font;
    }
}