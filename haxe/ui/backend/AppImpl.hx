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
        SetConfigFlags(RayLib.ConfigFlags.WINDOW_RESIZABLE);
        InitWindow(width, height, title);
        
        callback();
    }
    
    public override function start() {
        SetTargetFPS(60);
        
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
                    DrawFPS(GetScreenWidth() - 80, 5);
                }
            EndDrawing();
        }
        
        CloseWindow();
    }
}
