package haxe.ui.backend;

import RayLib.*;
import RayLib.Colors.*;
import haxe.ui.backend.raylib.MouseHelper;
import haxe.ui.backend.raylib.ScissorHelper;
import haxe.ui.backend.raylib.StyleHelper;
import haxe.ui.core.Component;
import haxe.ui.core.InteractiveComponent;
import haxe.ui.core.Screen;
import haxe.ui.core.TextDisplay;
import haxe.ui.events.MouseEvent;
import haxe.ui.events.UIEvent;
import haxe.ui.geom.Rectangle;
import haxe.ui.styles.Style;
import RayLib.Color;


class ComponentImpl extends ComponentBase {
    private var _eventMap:Map<String, UIEvent->Void> = new Map<String, UIEvent->Void>();
    
    public function new() {
        super();
    }
    
    private function recursiveReady() {
        var component:Component = cast(this, Component);
        component.ready();
        for (child in component.childComponents) {
            child.recursiveReady();
        }
    }
    
    private override function handlePosition(left:Null<Float>, top:Null<Float>, style:Style) {
        if (left == null && top == null) {
            return;
        }
    }
    
    private override function handleSize(width:Null<Float>, height:Null<Float>, style:Style) {
        if (width == null || height == null || width <= 0 || height <= 0) {
            return;
        }
        
        if (style != null && style.clip != null && style.clip == true) {
            cast(this, Component).componentClipRect = new Rectangle(0, 0, width, height);
        }
    }
    
    //***********************************************************************************************************
    // Display tree
    //***********************************************************************************************************
    
    private override function handleSetComponentIndex(child:Component, index:Int) {
    }

    private override function handleAddComponent(child:Component):Component {
        if (this.isReady) {
            child.ready();
        }
        return child;
    }

    private override function handleAddComponentAt(child:Component, index:Int):Component {
        if (this.isReady) {
            child.ready();
        }
        return child;
    }

    private override function handleRemoveComponent(child:Component, dispose:Bool = true):Component {
        return child;
    }

    private override function handleRemoveComponentAt(index:Int, dispose:Bool = true):Component {
        return null;
    }
    
    //***********************************************************************************************************
    // Style
    //***********************************************************************************************************
    private override function applyStyle(style:Style) {
    }
    
    //***********************************************************************************************************
    // Events
    //***********************************************************************************************************
    private override function mapEvent(type:String, listener:UIEvent->Void) {
        switch (type) {
            case MouseEvent.MOUSE_MOVE:
                if (_eventMap.exists(MouseEvent.MOUSE_MOVE) == false) {
                    MouseHelper.notify(MouseEvent.MOUSE_MOVE, __onMouseMove);
                    _eventMap.set(MouseEvent.MOUSE_MOVE, listener);
                }
                
            case MouseEvent.MOUSE_OVER:
                if (_eventMap.exists(MouseEvent.MOUSE_OVER) == false) {
                    MouseHelper.notify(MouseEvent.MOUSE_MOVE, __onMouseMove);
                    _eventMap.set(MouseEvent.MOUSE_OVER, listener);
                }
                
            case MouseEvent.MOUSE_OUT:
                if (_eventMap.exists(MouseEvent.MOUSE_OUT) == false) {
                    _eventMap.set(MouseEvent.MOUSE_OUT, listener);
                }

            case MouseEvent.MOUSE_DOWN:
                if (_eventMap.exists(MouseEvent.MOUSE_DOWN) == false) {
                    MouseHelper.notify(MouseEvent.MOUSE_DOWN, __onMouseDown);
                    MouseHelper.notify(MouseEvent.MOUSE_UP, __onMouseUp);
                    _eventMap.set(MouseEvent.MOUSE_DOWN, listener);
                }

            case MouseEvent.MOUSE_UP:
                if (_eventMap.exists(MouseEvent.MOUSE_UP) == false) {
                    MouseHelper.notify(MouseEvent.MOUSE_UP, __onMouseUp);
                    _eventMap.set(MouseEvent.MOUSE_UP, listener);
                }

            case MouseEvent.CLICK:
                if (_eventMap.exists(MouseEvent.CLICK) == false) {
                    _eventMap.set(MouseEvent.CLICK, listener);

                    if (_eventMap.exists(MouseEvent.MOUSE_DOWN) == false) {
                        MouseHelper.notify(MouseEvent.MOUSE_DOWN, __onMouseDown);
                        MouseHelper.notify(MouseEvent.MOUSE_UP, __onMouseUp);
                        _eventMap.set(MouseEvent.MOUSE_DOWN, listener);
                    }

                    if (_eventMap.exists(MouseEvent.MOUSE_UP) == false) {
                        MouseHelper.notify(MouseEvent.MOUSE_UP, __onMouseUp);
                        _eventMap.set(MouseEvent.MOUSE_UP, listener);
                    }
                }
                
            case MouseEvent.MOUSE_WHEEL:
                if (_eventMap.exists(MouseEvent.MOUSE_WHEEL) == false) {
                    MouseHelper.notify(MouseEvent.MOUSE_MOVE, __onMouseMove);
                    MouseHelper.notify(MouseEvent.MOUSE_WHEEL, __onMouseWheel);
                    _eventMap.set(MouseEvent.MOUSE_WHEEL, listener);
                }
                
        }
    }
    
    private override function unmapEvent(type:String, listener:UIEvent->Void) {
        switch (type) {
            case MouseEvent.MOUSE_MOVE:
                _eventMap.remove(type);
                if (_eventMap.exists(MouseEvent.MOUSE_MOVE) == false
                    && _eventMap.exists(MouseEvent.MOUSE_OVER) == false
                    && _eventMap.exists(MouseEvent.MOUSE_WHEEL) == false) {
                    MouseHelper.remove(MouseEvent.MOUSE_MOVE, __onMouseMove);
                }
                
            case MouseEvent.MOUSE_OVER:
                _eventMap.remove(type);
                if (_eventMap.exists(MouseEvent.MOUSE_MOVE) == false
                    && _eventMap.exists(MouseEvent.MOUSE_OVER) == false
                    && _eventMap.exists(MouseEvent.MOUSE_WHEEL) == false) {
                    MouseHelper.remove(MouseEvent.MOUSE_MOVE, __onMouseMove);
                }
                
            case MouseEvent.MOUSE_OUT:
                _eventMap.remove(type);

            case MouseEvent.MOUSE_DOWN:
                _eventMap.remove(type);
                if (_eventMap.exists(MouseEvent.MOUSE_DOWN) == false
                    && _eventMap.exists(MouseEvent.RIGHT_MOUSE_DOWN) == false) {
                    MouseHelper.remove(MouseEvent.MOUSE_DOWN, __onMouseDown);
                }

            case MouseEvent.MOUSE_UP:
                _eventMap.remove(type);
                if (_eventMap.exists(MouseEvent.MOUSE_UP) == false
                    && _eventMap.exists(MouseEvent.RIGHT_MOUSE_UP) == false) {
                    MouseHelper.remove(MouseEvent.MOUSE_UP, __onMouseUp);
                }
            
            case MouseEvent.MOUSE_WHEEL:
                _eventMap.remove(type);
                MouseHelper.remove(MouseEvent.MOUSE_WHEEL, __onMouseWheel);
                if (_eventMap.exists(MouseEvent.MOUSE_MOVE) == false
                    && _eventMap.exists(MouseEvent.MOUSE_OVER) == false
                    && _eventMap.exists(MouseEvent.MOUSE_WHEEL) == false) {
                    MouseHelper.remove(MouseEvent.MOUSE_MOVE, __onMouseMove);
                }
                
            case MouseEvent.CLICK:
                _eventMap.remove(type);
        }
    }
    
    // lets cache certain items so we dont have to loop multiple times per frame
    private var _cachedScreenX:Null<Float> = null;
    private var _cachedScreenY:Null<Float> = null;
    private var _cachedClipComponent:Component = null;
    private var _cachedClipComponentNone:Null<Bool> = null;
    private var _cachedRootComponent:Component = null;
    private var _cachedOpacity:Null<Float> = null;
    
    private function calcOpacity():Float {
        if (_cachedOpacity != null) {
            return _cachedOpacity;
        }
        
        var opacity:Float = 1;
        var c:Component = cast(this, Component);
        while (c != null) {
            if (c.style.opacity != null) {
                opacity *= c.style.opacity;
            }
            c = c.parentComponent;
        }
        
        _cachedOpacity = opacity;
        
        return opacity;
    }
    
    private function clearCaches() {
        _cachedScreenX = null;
        _cachedScreenY = null;
        _cachedClipComponent = null;
        _cachedClipComponentNone = null;
        _cachedRootComponent = null;
        _cachedOpacity = null;
    }
    
    private function cacheScreenPos() {
        if (_cachedScreenX != null && _cachedScreenY != null) {
            return;
        }
        
        var c:Component = cast(this, Component);
        var xpos:Float = 0;
        var ypos:Float = 0;
        while (c != null) {
            if (c.parentComponent == null) {
                xpos += c.left / Toolkit.scaleX;
                ypos += c.top / Toolkit.scaleY;
            } else {
                xpos += c.left;
                ypos += c.top;
            }
            if (c.componentClipRect != null) {
                xpos -= c.componentClipRect.left;
                ypos -= c.componentClipRect.top;
            }
            c = c.parentComponent;
        }
        
        _cachedScreenX = xpos;
        _cachedScreenY = ypos;
    }
    
    private var screenX(get, null):Float;
    private function get_screenX():Float {
        cacheScreenPos();
        return _cachedScreenX;
    }

    private var screenY(get, null):Float;
    private function get_screenY():Float {
        cacheScreenPos();
        return _cachedScreenY;
    }

    private function findRootComponent():Component {
        if (_cachedRootComponent != null) {
            return _cachedRootComponent;
        }
        
        var c:Component = cast(this, Component);
        while (c.parentComponent != null) {
            c = c.parentComponent;
        }
        
        _cachedRootComponent = c;
        
        return c;
    }
    
    private function isRootComponent():Bool {
        return (findRootComponent() == this);
    }
    
    private function findClipComponent():Component {
        if (_cachedClipComponent != null) {
            return _cachedClipComponent;
        } else if (_cachedClipComponentNone == true) {
            return null;
        }
        
        var c:Component = cast(this, Component);
        var clip:Component = null;
        while (c != null) {
            if (c.componentClipRect != null) {
                clip = c;
                break;
            }
            c = c.parentComponent;
        }

        _cachedClipComponent = clip;
        if (clip == null) {
            _cachedClipComponentNone = true;
        }
        
        return clip;
    }
    
    @:access(haxe.ui.core.Component)
    private function inBounds(x:Float, y:Float):Bool {
        if (cast(this, Component).hidden == true) {
            return false;
        }

        var b:Bool = false;
        var sx = screenX * Toolkit.scaleX;
        var sy = screenY * Toolkit.scaleY;
        var cx = cast(this, Component).componentWidth * Toolkit.scaleX;
        var cy = cast(this, Component).componentHeight * Toolkit.scaleY;

        if (x >= sx && y >= sy && x <= sx + cx && y <= sy + cy) {
            b = true;
        }

        // let make sure its in the clip rect too
        if (b == true) {
            var clip:Component = findClipComponent();
            if (clip != null) {
                b = false;
                var sx = (clip.screenX + clip.componentClipRect.left) * Toolkit.scaleX;
                var sy = (clip.screenY + clip.componentClipRect.top) * Toolkit.scaleY;
                var cx = clip.componentClipRect.width * Toolkit.scaleX;
                var cy = clip.componentClipRect.height * Toolkit.scaleY;
                if (x >= sx && y >= sy && x <= sx + cx && y <= sy + cy) {
                    b = true;
                }
            }
        }
        return b;
    }
    
    private function isOffscreen():Bool {
        var x:Float = screenX;
        var y:Float = screenY;
        var w:Float = this.width;
        var h:Float = this.height;
        
        var clipComponent = findClipComponent();
        var thisRect = new Rectangle(x, y, w, h);
        if (clipComponent != null && clipComponent != this) {
            var screenClipRect = new Rectangle(clipComponent.screenX + clipComponent.componentClipRect.left, clipComponent.screenY + clipComponent.componentClipRect.top, clipComponent.componentClipRect.width, clipComponent.componentClipRect.height);
            return !screenClipRect.intersects(thisRect);
        } else {
            var screenRect = new Rectangle(0, 0, Screen.instance.width, Screen.instance.height);
            return !screenRect.intersects(thisRect);
        }
        
        return false;
    }
    
    private function hasComponentOver(ref:Component, x:Float, y:Float):Bool {
        var array:Array<Component> = getComponentsAtPoint(x, y);
        if (array.length == 0) {
            return false;
        }

        return !hasChildRecursive(cast ref, cast array[array.length - 1]);
    }

    private function getComponentsAtPoint(x:Float, y:Float):Array<Component> {
        var array:Array<Component> = new Array<Component>();
        for (r in Screen.instance.rootComponents) {
            findChildrenAtPoint(r, x, y, array);
        }
        return array;
    }

    private function findChildrenAtPoint(child:Component, x:Float, y:Float, array:Array<Component>) {
        if (child.inBounds(x, y) == true) {
            array.push(child);
            for (c in child.childComponents) {
                findChildrenAtPoint(c, x, y, array);
            }
        }
    }

    public function hasChildRecursive(parent:Component, child:Component):Bool {
        if (parent == child) {
            return true;
        }
        var r = false;
        for (t in parent.childComponents) {
            if (t == child) {
                r = true;
                break;
            }

            r = hasChildRecursive(t, child);
            if (r == true) {
                break;
            }
        }

        return r;
    }
    
    private var lastMouseX:Float = -1;
    private var lastMouseY:Float = -1;
    private var _mouseOverFlag:Bool = false;
    private function __onMouseMove(event:MouseEvent) {
        var x = event.screenX;
        var y = event.screenY;
        
        lastMouseX = x;
        lastMouseY = y;
        var i = inBounds(x, y);
        if (i == true) {
            var fn:UIEvent->Void = _eventMap.get(haxe.ui.events.MouseEvent.MOUSE_MOVE);
            if (fn != null) {
                var mouseEvent = new haxe.ui.events.MouseEvent(haxe.ui.events.MouseEvent.MOUSE_MOVE);
                mouseEvent.screenX = x / Toolkit.scaleX;
                mouseEvent.screenY = y / Toolkit.scaleY;
                fn(mouseEvent);
            }
        }
        if (i == true && _mouseOverFlag == false) {
            if (hasComponentOver(cast this, x, y) == true) {
                return;
            }
            _mouseOverFlag = true;
            var fn:UIEvent->Void = _eventMap.get(haxe.ui.events.MouseEvent.MOUSE_OVER);
            if (style != null && style.cursor != null && (this is InteractiveComponent)) {
                MouseHelper.cursor = style.cursor;
            }
            if (fn != null) {
                var mouseEvent = new haxe.ui.events.MouseEvent(haxe.ui.events.MouseEvent.MOUSE_OVER);
                mouseEvent.screenX = x / Toolkit.scaleX;
                mouseEvent.screenY = y / Toolkit.scaleY;
                fn(mouseEvent);
            }
        } else if (i == false && _mouseOverFlag == true) {
            _mouseOverFlag = false;
            var fn:UIEvent->Void = _eventMap.get(haxe.ui.events.MouseEvent.MOUSE_OUT);
            if ((this is InteractiveComponent)) {
                MouseHelper.cursor = null;
            }
            if (fn != null) {
                var mouseEvent = new haxe.ui.events.MouseEvent(haxe.ui.events.MouseEvent.MOUSE_OUT);
                mouseEvent.screenX = x / Toolkit.scaleX;
                mouseEvent.screenY = y / Toolkit.scaleY;
                fn(mouseEvent);
            }
        }
    }

    private var _mouseDownFlag:Bool = false;
    private function __onMouseDown(event:MouseEvent) {
        var button:Int = event.data;
        var x = event.screenX;
        var y = event.screenY;
        
        lastMouseX = x;
        lastMouseY = y;
        var i = inBounds(x, y);
        if (i == true && _mouseDownFlag == false) {
            if (hasComponentOver(cast this, x, y) == true) {
                return;
            }
            _mouseDownFlag = true;
            var type = button == 0 ? haxe.ui.events.MouseEvent.MOUSE_DOWN: haxe.ui.events.MouseEvent.RIGHT_MOUSE_DOWN;
            var fn:UIEvent->Void = _eventMap.get(type);
            if (fn != null) {
                var mouseEvent = new haxe.ui.events.MouseEvent(type);
                mouseEvent.screenX = x / Toolkit.scaleX;
                mouseEvent.screenY = y / Toolkit.scaleY;
                fn(mouseEvent);
            }
        }
    }

    private function __onMouseUp(event:MouseEvent) {
        var button:Int = event.data;
        var x = event.screenX;
        var y = event.screenY;
        
        lastMouseX = x;
        lastMouseY = y;
        var i = inBounds(x, y);
        if (i == true) {
            if (hasComponentOver(cast this, x, y) == true) {
                return;
            }
			
            if (_mouseDownFlag == true) {
                var type = button == 0 ? haxe.ui.events.MouseEvent.CLICK: haxe.ui.events.MouseEvent.RIGHT_CLICK;
                var fn:UIEvent->Void = _eventMap.get(type);
                if (fn != null) {
                    var mouseEvent = new haxe.ui.events.MouseEvent(type);
                    mouseEvent.screenX = x / Toolkit.scaleX;
                    mouseEvent.screenY = y / Toolkit.scaleY;
                    fn(mouseEvent);
                }
            }

            _mouseDownFlag = false;
            var type = button == 0 ? haxe.ui.events.MouseEvent.MOUSE_UP: haxe.ui.events.MouseEvent.RIGHT_MOUSE_UP;
            var fn:UIEvent->Void = _eventMap.get(type);
            if (fn != null) {
                var mouseEvent = new haxe.ui.events.MouseEvent(type);
                mouseEvent.screenX = x / Toolkit.scaleX;
                mouseEvent.screenY = y / Toolkit.scaleY;
                fn(mouseEvent);
            }
        }
        _mouseDownFlag = false;
    }
    
    private function __onMouseWheel(event:MouseEvent) {
        var delta = event.delta;
        var fn = _eventMap.get(MouseEvent.MOUSE_WHEEL);

        if (fn == null) {
            return;
        }

        if (!inBounds(lastMouseX, lastMouseY)) {
            return;
        }

        var mouseEvent = new MouseEvent(MouseEvent.MOUSE_WHEEL);
        mouseEvent.screenX = lastMouseX / Toolkit.scaleX;
        mouseEvent.screenY = lastMouseY / Toolkit.scaleY;
        mouseEvent.delta = -Math.max(-1, Math.min(1, -delta));
        fn(mouseEvent);
    }
    
    //***********************************************************************************************************
    // Text related
    //***********************************************************************************************************
    public override function createTextDisplay(text:String = null):TextDisplay {
        return super.createTextDisplay(text);
    }
    
    //***********************************************************************************************************
    // RAYLIB
    //***********************************************************************************************************
    @:access(haxe.ui.core.Component)
    public function draw() {
        if (this.isReady == false || cast(this, Component).hidden == true) {
            return;
        }
        
        clearCaches();
        
        if (isOffscreen() == true) {
            return;
        }
        
        var style:Style = this.style;
        if (style == null) {
            return;
        }
        
        var x:Int = Std.int(screenLeft);
        var y:Int = Std.int(screenTop);
        var w:Int = Std.int(width);
        var h:Int = Std.int(height);
        if (w == 0 || height == 0) {
            return;
        }
        
        var clipRect:Rectangle = cast(this, Component).componentClipRect;
        if (clipRect != null) {
            var clx = Std.int((x + clipRect.left) * Toolkit.scaleX);
            var cly = Std.int((y + clipRect.top) * Toolkit.scaleY);
            var clw = Math.ceil(clipRect.width * Toolkit.scaleX);
            var clh = Math.ceil(clipRect.height * Toolkit.scaleY);
            if (clw >= 0 && clh >= 0) {
                ScissorHelper.pushScissor(clx, cly, clw, clh);
            }
        }
        
        StyleHelper.drawStyle(style, screenLeft, screenTop, width, height, calcOpacity());
        
        if (_textDisplay != null) {
            _textDisplay.draw(x, y);
        }
        
        if (_textInput != null) {
            _textInput.draw(x, y);
        }
        
        if (_imageDisplay != null) {
            _imageDisplay.draw(x, y);
        }
        
        for (child in childComponents) {
            child.draw();
        }
        
        if (clipRect != null) {
            ScissorHelper.popScissor();
        }
        
        clearCaches();
    }
}