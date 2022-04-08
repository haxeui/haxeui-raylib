package haxe.ui.backend.raylib;

import haxe.ui.filters.DropShadow;
import haxe.ui.filters.Filter;
import haxe.ui.styles.Style;
import RayLib.*;
import RayLib.Color;

@:unreflective
class StyleHelper {
    public static function drawStyle(style:Style, xpos:Float, ypos:Float, width:Float, height:Float, opacity:Float = 1):Void {
        /*
        xpos = Math.round(xpos);
        ypos = Math.round(ypos);
        width = Math.round(width);
        height = Math.round(height);
        */
        
        var x:Int = Std.int(xpos);
        var y:Int = Std.int(ypos);
        var w:Int = Std.int(width);
        var h:Int = Std.int(height);
        
        var orgX = x;
        var orgY = y;
        var orgW = w;
        var orgH = h;
        
        if (w == 0 || height == 0) {
            return;
        }
        
        if (style.backgroundColor != null) {
            var backgroundOpacity:Float = opacity;
            if (style.backgroundOpacity != null) {
                backgroundOpacity = style.backgroundOpacity;
            }
            if (style.backgroundColorEnd != null && style.backgroundColor != style.backgroundColorEnd) {
                var gradientType:String = "vertical";
                if (style.backgroundGradientStyle != null) {
                    gradientType = style.backgroundGradientStyle;
                }
                
                if (gradientType == "vertical") {
                    DrawRectangleGradientV(x, y, w, h, col(style.backgroundColor), col(style.backgroundColorEnd, backgroundOpacity));
                } else if (gradientType == "horizontal") {
                    DrawRectangleGradientH(x, y, w, h, col(style.backgroundColor), col(style.backgroundColorEnd, backgroundOpacity));
                }
            } else {
                DrawRectangle(x, y, w, h, col(style.backgroundColor, backgroundOpacity));
            }
        }
        
        if (style.borderLeftSize != null &&
            style.borderLeftSize == style.borderRightSize &&
            style.borderLeftSize == style.borderBottomSize &&
            style.borderLeftSize == style.borderTopSize
            
            && style.borderLeftColor != null
            && style.borderLeftColor == style.borderRightColor
            && style.borderLeftColor == style.borderBottomColor
            && style.borderLeftColor == style.borderTopColor) { // full border
            
            var borderSize:Int = Std.int(style.borderLeftSize);    
            DrawRectangle(x, y, w, borderSize, col(style.borderLeftColor)); // top
            DrawRectangle(x, y + h - borderSize, w, borderSize, col(style.borderLeftColor)); // bottom
            DrawRectangle(x, y, borderSize, h, col(style.borderLeftColor)); // left
            DrawRectangle(x + w - borderSize, y, borderSize, h, col(style.borderLeftColor)); // right
        } else { // compound border
            if (style.borderTopSize != null && style.borderTopSize > 0) {
                DrawRectangle(x, y, w, Std.int(style.borderTopSize), col(style.borderTopColor)); // top
            }
            
            if (style.borderBottomSize != null && style.borderBottomSize > 0) {
                DrawRectangle(x, y + h - Std.int(style.borderBottomSize), w, Std.int(style.borderBottomSize), col(style.borderBottomColor)); // bottom
            }
            
            if (style.borderLeftSize != null && style.borderLeftSize > 0) {
                DrawRectangle(x, y, Std.int(style.borderLeftSize), h, col(style.borderLeftColor)); // left
            }
            
            if (style.borderRightSize != null && style.borderRightSize > 0) {
                DrawRectangle(x + w - Std.int(style.borderRightSize), y, Std.int(style.borderRightSize), h, col(style.borderRightColor)); // right
            }
        }
    
        if (style.filter != null) {
            var f:Filter = style.filter[0];
            if ((f is DropShadow)) {
                var dropShadow:DropShadow = cast(f, DropShadow);
                if (dropShadow.inner == true) {
                    drawShadow(dropShadow.color, x, y, w, h, Std.int(dropShadow.distance), dropShadow.inner);
                } else {
                    drawShadow(dropShadow.color, orgX - 1, orgY - 1, orgW, orgH, Std.int(dropShadow.distance), dropShadow.inner);
                }
            }
        }
    }
    
    private static function drawShadow(color:Int, x:Int, y:Int, w:Int, h:Int, size:Int, inset:Bool = false):Void {
        size = Std.int(size * Toolkit.scale);
        if (inset == false) {
            for (i in 0...size) {
                DrawRectangle(x + i + 1, y + h + 1 + i, w + 0, 1, Fade(col(color), .1)); // bottom
                DrawRectangle(x + w + 1 + i, y + i + 1, 1, h + 1, Fade(col(color), .1)); // right
            }
        } else {
            for (i in 0...size) {
                DrawRectangle(x + i, y + i, w - i, 1, Fade(col(color), .1)); // top
                DrawRectangle(x + i, y + i, 1, h - i, Fade(col(color), .1)); // left
            }
        }
    }
    
    public static  inline function col(c:Int, opacity:Float = 1) {
        var o = Std.int(opacity * 255);
        return Color.create((c & 0xff0000) >> 16, (c & 0x00ff00) >> 8, (c & 0x0000ff), o);
    }
}