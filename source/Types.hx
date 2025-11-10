package;

class KeyValueArray<T> {
    public var map:Map<String, T>;
    public var keys:Array<String>;
    public var values:Array<T>;

    public function new(keys:Array<String>, values:Array<T>) {
        if (keys.length == values.length) {
            var map:Map<String, T> = [];
            for (i => key in keys) map.set(key, values[i]);

            this.map = map;
            this.keys = keys;
            this.values = values;
        } else trace('keys and values must be the same length!');
    }
}