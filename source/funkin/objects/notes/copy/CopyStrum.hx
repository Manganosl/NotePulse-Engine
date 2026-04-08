package funkin.objects.notes.copy;

import funkin.objects.notes.StrumNote;
import funkin.objects.notes.PlayField;

class CopyStrum extends StrumNote {
    public var sourceStrum:StrumNote;

    public function new(sourceStrum:StrumNote, parentField:PlayField) {
        this.sourceStrum = sourceStrum;
        var sourcePlayer = parentField.player; // So this was the problem, huh?
        super(sourceStrum.x, sourceStrum.y, sourceStrum.noteData, sourcePlayer);
        
        this.parentField = parentField;

        syncValues();
    }

    override function update(elapsed:Float) {
        syncValues();
        super.update(elapsed);

        if (sourceStrum != null && !sourceStrum.exists) {
            this.kill();
        }
    }

    public function syncValues() {
        if (sourceStrum == null) return;

        this.trackedScale = sourceStrum.trackedScale;
        this.resetAnim = sourceStrum.resetAnim;

        if (sourceStrum.animation.curAnim != null) {
            var animName = sourceStrum.animation.curAnim.name;
            
            if (this.animation.curAnim == null || this.animation.curAnim.name != animName) {
                this.playAnim(animName, true);
            } else {
                this.animation.curAnim.curFrame = sourceStrum.animation.curAnim.curFrame;
            }
        }

        if (this.texture != sourceStrum.texture) {
            this.texture = sourceStrum.texture;
        }

        this.useRGBShader = sourceStrum.useRGBShader;
        if (sourceStrum.rgbShader != null && this.rgbShader != null && this.useRGBShader) {
            this.rgbShader.r = sourceStrum.rgbShader.r;
            this.rgbShader.g = sourceStrum.rgbShader.g;
            this.rgbShader.b = sourceStrum.rgbShader.b;
            this.rgbShader.enabled = sourceStrum.rgbShader.enabled;
        }

        @:privateAccess {
            if (sourceStrum.sustainSplash != null && this.sustainSplash != null) {
                this.sustainSplash.visible = sourceStrum.sustainSplash.visible;
                this.sustainSplash.alpha = sourceStrum.sustainSplash.alpha;
                
                if (sourceStrum.sustainSplash.animation.curAnim != null) {
                    var splashAnim = sourceStrum.sustainSplash.animation.curAnim.name;
                    if (this.sustainSplash.animation.curAnim == null || this.sustainSplash.animation.curAnim.name != splashAnim) {
                        this.sustainSplash.animation.play(splashAnim, true);
                    }
                    this.sustainSplash.animation.curAnim.curFrame = sourceStrum.sustainSplash.animation.curAnim.curFrame;
                }
            }
        }
    }
}