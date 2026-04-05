package funkin.objects.notes;

class CopyField extends PlayField {
    public var sourceField:PlayField;

    override public function new(sourceField:PlayField, player:Int) {
        this.sourceField = sourceField;
        super(player);
    }
}