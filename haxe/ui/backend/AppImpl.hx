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
        
        if (Toolkit.backendProperties.getPropBool("haxe.ui.raylib.msaa", true) == true) {
            SetConfigFlags(RayLib.ConfigFlags.MSAA_4X_HINT);
        }
        if (Toolkit.backendProperties.getPropBool("haxe.ui.raylib.vsync", false) == true) {
            SetConfigFlags(RayLib.ConfigFlags.VSYNC_HINT);
        }
        if (Toolkit.backendProperties.getPropBool("haxe.ui.raylib.window.resizable", true) == true) {
            SetConfigFlags(RayLib.ConfigFlags.WINDOW_RESIZABLE);
        }
        InitWindow(width, height, title);
        
        callback();
    }
    
    public override function start() {
        SetTargetFPS(Toolkit.backendProperties.getPropInt("haxe.ui.raylib.targetFPS", 60));
        
        var drawFPSDefault = false;
        #if debug
        drawFPSDefault = true;
        #end
        var drawFPS = Toolkit.backendProperties.getPropBool("haxe.ui.raylib.showFPS", drawFPSDefault);

        while (!WindowShouldClose()) {
            Screen.instance.update();
            
            BeginDrawing();
                ClearBackground(Colors.RAYWHITE);
                Screen.instance.draw();
                if (drawFPS == true) {
                    DrawRectangle(GetScreenWidth() - 85, 0, 80, 25, Colors.RAYWHITE);
                    DrawFPS(GetScreenWidth() - 80, 5);
                }
            EndDrawing();
        }
        
        CloseWindow();
    }
}
