package haxe.ui.backend;

class CallLaterImpl {
    public function new(fn:Void->Void) {
        fn();
    }
}