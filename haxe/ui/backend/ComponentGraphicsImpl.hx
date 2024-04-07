package haxe.ui.backend;

import cpp.NativeArray;
import haxe.io.Bytes;
import haxe.ui.core.Component;
import haxe.ui.geom.Point;
import RayLib.*;
import RayLib.Vector2;
import RayLib.Image;
import RayLib.ImageRef;
import RayLib.Colors;
import RayLib.Texture;
import RayLib.TextureRef;
import RayLib.PixelFormat;
import haxe.ui.util.Color;


class ComponentGraphicsImpl extends ComponentGraphicsBase {
    public function new(component:Component) {
        super(component);
    }
    
    //private var _image:ImageRef = null;
    private var _texture:Texture = null;
    private var _hasTexture:Bool = false;
    
    public function draw() {
        var currentPosition:Point = new Point();
        var currentStrokeColor:Color = -1;
        var currentStrokeThickness:Float = 1;
        var currentStrokeAlpha:Int = 255;
        var currentFillColor:Color = -1;
        var currentFillAlpha:Int = 255;
        
        var sx = Std.int(_component.screenLeft);
        var sy = Std.int(_component.screenTop);
        var w = Std.int(_component.width);
        var h = Std.int(_component.height);
        
        for (command in _drawCommands) {
            switch (command) {
                case Clear:
                    DrawRectangle(sx,
                                  sy,
                                  w,
                                  h,
                                  RayLib.Colors.RAYWHITE);
                case MoveTo(x, y):
                    currentPosition.x = x;
                    currentPosition.y = y;
                case LineTo(x, y):
                    if (currentStrokeColor != -1) {
                        DrawLineEx(Vector2.create(sx + currentPosition.x, sy + currentPosition.y),
                                   Vector2.create(sx + x, sy + y),
                                   currentStrokeThickness + .5,
                                   RayLib.Color.create(currentStrokeColor.r,
                                                       currentStrokeColor.g,
                                                       currentStrokeColor.b,
                                                       currentStrokeAlpha));
                    }
                    currentPosition.x = x;
                    currentPosition.y = y;
                case StrokeStyle(color, thickness, alpha):
                    if (thickness != null) {
                        currentStrokeThickness = thickness;
                    }
                    if (color != null) {
                        currentStrokeColor = color;
                    } else {
                        currentStrokeColor = -1;
                    }
                    if (alpha != null) {
                        currentStrokeAlpha = Std.int(alpha * 255);
                    }
                case FillStyle(color, alpha):
                    if (color != null) {
                        currentFillColor = color;
                    } else {
                        currentFillColor = -1;
                    }
                    if (alpha != null) {
                        currentFillAlpha = Std.int(alpha * 255);
                    }
                case Circle(x, y, radius):
                    if (currentFillColor != -1) {
                        DrawCircleGradient(Std.int(sx + x),
                                           Std.int(sy + y),
                                           radius + currentStrokeThickness - 1,
                                           RayLib.Color.create(currentFillColor.r,
                                                               currentFillColor.g,
                                                               currentFillColor.b,
                                                               currentFillAlpha),
                                           RayLib.Color.create(currentFillColor.r,
                                                               currentFillColor.g,
                                                               currentFillColor.b,
                                                               currentFillAlpha));
                    }
                    if (currentStrokeColor != -1) {
                        DrawCircle(Std.int(sx + x),
                                   Std.int(sy + y),
                                   radius + currentStrokeThickness - 1,
                                   RayLib.Color.create(currentStrokeColor.r,
                                                       currentStrokeColor.g,
                                                       currentStrokeColor.b,
                                                       currentStrokeAlpha));
                    }
                case CurveTo(controlX, controlY, anchorX, anchorY):
                    if (currentStrokeColor != -1) {
                        DrawLineBezierQuad(Vector2.create(sx + currentPosition.x, sy + currentPosition.y),
                                           Vector2.create(sx + anchorX, sy + anchorY),
                                           Vector2.create(sx + controlX, sy + controlY),
                                           currentStrokeThickness + .5,
                                           RayLib.Color.create(currentStrokeColor.r,
                                                               currentStrokeColor.g,
                                                               currentStrokeColor.b,
                                                               currentStrokeAlpha));
                    }
                    currentPosition.x = anchorX;
                    currentPosition.y = anchorY;
                case CubicCurveTo(controlX1, controlY1, controlX2, controlY2, anchorX, anchorY):
                    if (currentStrokeColor != -1) {
                        DrawLineBezierCubic(Vector2.create(sx + currentPosition.x, sy + currentPosition.y),
                                            Vector2.create(sx + anchorX, sy + anchorY),
                                            Vector2.create(sx + controlX1, sy + controlY1),
                                            Vector2.create(sx + controlX2, sy + controlY2),
                                            currentStrokeThickness + .5,
                                            RayLib.Color.create(currentStrokeColor.r,
                                                                currentStrokeColor.g,
                                                                currentStrokeColor.b,
                                                                currentStrokeAlpha));
                    }
                    currentPosition.x = anchorX;
                    currentPosition.y = anchorY;
               case Rectangle(x, y, width, height):
                    if (currentFillColor != -1) {
                        DrawRectangle(Std.int(sx + x),
                                      Std.int(sy + y),
                                      Std.int(width),
                                      Std.int(height),
                                      RayLib.Color.create(currentFillColor.r,
                                                          currentFillColor.g,
                                                          currentFillColor.b,
                                                          currentFillAlpha));
                    }
               case SetPixel(x, y, color):    
               case SetPixels(pixels):   
                   if (_hasTexture == false) {
                       _hasTexture = true;
                       var data = NativeArray.address(pixels.getData(), 0);
                       var image = Image.create(data.rawCast(), Std.int(_component.width), Std.int(_component.height), 1, PixelFormat.UNCOMPRESSED_R8G8B8A8);
                       _texture = LoadTextureFromImage(image);
                   }
                   var data = NativeArray.address(pixels.getData(), 0);
                   UpdateTexture(_texture, data.rawCast());
               DrawTexture(_texture, sx, sy, Colors.WHITE);
               case Image(resource, x, y, width, height):
            }
        }
    }
}