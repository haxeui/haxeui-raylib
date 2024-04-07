package haxe.ui.backend.raylib;

import RayLib.*;
import RayLib.MouseButton;
import haxe.ui.events.MouseEvent;
import RayLib.MouseCursor;

class MouseHelper {
    private static var _callbacks:Map<String, Array<MouseEvent->Void>> = new Map<String, Array<MouseEvent->Void>>();
    
    public static var mouseX:Int = 0;
    public static var mouseY:Int = 0;
    
    public static function notify(event:String, callback:MouseEvent->Void) {
        var list = _callbacks.get(event);
        if (list == null) {
            list = new Array<MouseEvent->Void>();
            _callbacks.set(event, list);
        }
        
        if (!list.contains(callback)) {
            list.push(callback);
        }
    }
    
    public static function update() {
        var mx = GetMouseX();
        var my = GetMouseY();
        if (mx != mouseX || my != mouseY) {
            mouseX = mx;
            mouseY = my;
            onMouseMove(mouseX, mouseY);
        }
        
        if (IsMouseButtonPressed(MouseButton.LEFT)) {
            onMouseDown(0, mouseX, mouseY);
        }
        if (IsMouseButtonReleased(MouseButton.LEFT)) {
            onMouseUp(0, mouseX, mouseY);
        }
        var n = GetMouseWheelMove();
        if (n != 0) {
            onMouseWheel(n);
        }
    }
    
    public static function remove(event:String, callback:MouseEvent->Void) {
        var list = _callbacks.get(event);
        if (list != null) {
            list.remove(callback);
            if (list.length == 0) {
                _callbacks.remove(event);
            }
        }
    }
    
    private static function onMouseDown(button:Int, x:Int, y:Int) {
        var list = _callbacks.get(MouseEvent.MOUSE_DOWN);
        if (list == null || list.length == 0) {
            return;
        }
        
        list = list.copy();
        
        var event = new MouseEvent(MouseEvent.MOUSE_DOWN);
        event.screenX = x;
        event.screenY = y;
        event.data = button;
        for (l in list) {
            l(event);
        }
    }
    
    private static function onMouseUp(button:Int, x:Int, y:Int) {
        var list = _callbacks.get(MouseEvent.MOUSE_UP);
        if (list == null || list.length == 0) {
            return;
        }
        
        list = list.copy();
        
        var event = new MouseEvent(MouseEvent.MOUSE_UP);
        event.screenX = x;
        event.screenY = y;
        event.data = button;
        for (l in list) {
            l(event);
        }
    }
    
    private static function onMouseMove(x:Int, y:Int) {
        var list = _callbacks.get(MouseEvent.MOUSE_MOVE);
        if (list == null || list.length == 0) {
            return;
        }
        
        list = list.copy();
        
        var event = new MouseEvent(MouseEvent.MOUSE_MOVE);
        event.screenX = x;
        event.screenY = y;
        for (l in list) {
            l(event);
        }
    }
    
    private static function onMouseWheel(delta:Float) {
        var list = _callbacks.get(MouseEvent.MOUSE_WHEEL);
        if (list == null || list.length == 0) {
            return;
        }
        
        list = list.copy();
        
        var event = new MouseEvent(MouseEvent.MOUSE_WHEEL);
        event.delta = delta;
        event.screenX = mouseX;
        event.screenY = mouseY;
        for (l in list) {
            l(event);
        }
    }
    
    private static var _cursor:String = null;
    public static var cursor(get, set):String;
    private static function get_cursor():String {
        return _cursor;
    }
    private static function set_cursor(value:String):String {
        if (_cursor == value) {
            return value;
        }
        
        _cursor = value;
        if (_cursor == null) {
            SetMouseCursor(MouseCursor.DEFAULT);
        } else {
            switch (_cursor) {
                case "pointer":
                    SetMouseCursor(MouseCursor.POINTING_HAND);
            }
        }
        
        return value;
    }
}