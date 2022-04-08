package haxe.ui.backend;

import RayLib.*;
import RayLib.Colors;
import haxe.ui.backend.raylib.KeyboardHelper;
import haxe.ui.backend.raylib.MouseHelper;
import haxe.ui.core.Screen;

class AppImpl extends AppBase {
    public function new() {
    }
    
    private override function init(callback:Void->Void, onEnd:Void->Void = null) {
        var title:String = Toolkit.backendProperties.getProp("haxe.ui.raylib.title", "");
        var width:Int = Toolkit.backendProperties.getPropInt("haxe.ui.raylib.width", 1024);
        var height:Int = Toolkit.backendProperties.getPropInt("haxe.ui.raylib.height", 768);
        
        SetConfigFlags(RayLib.ConfigFlags.MSAA_4X_HINT);
        SetConfigFlags(RayLib.ConfigFlags.VSYNC_HINT);
        InitWindow(width, height, title);
        
        callback();
    }
    
    public override function start() {
        SetTargetFPS(60);
        
        while (!WindowShouldClose()) {
            Screen.instance.update();
            
            BeginDrawing();
                ClearBackground(Colors.RAYWHITE);
                Screen.instance.draw();
            EndDrawing();
        }
        
        CloseWindow();
    }
}
