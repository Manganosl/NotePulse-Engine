package funkin.game.modchart;

import funkin.game.modchart.events.ModEvent;
import funkin.game.modchart.events.BaseEvent;

class EventTimeline {
    public var modEvents:Map<String, Array<ModEvent>> = [];
    public var events:Array<BaseEvent> = [];

    var schedules:Array<Array<ModEvent>> = [];

    var pending:Array<BaseEvent> = [];
    var updating:Bool = false;

    public function new() {}

    public function addMod(modName:String){
        var list:Array<ModEvent> = [];
        var old = modEvents.get(modName);
        modEvents.set(modName, list);
        if (old != null){
            var i = schedules.indexOf(old);
            if (i >= 0){ schedules[i] = list; return; }
        }
        schedules.push(list);
    }

    public function addEvent(event:BaseEvent){
        if (updating){
            pending.push(event);
            return;
        }
        insertEvent(event);
    }

    function insertEvent(event:BaseEvent){
        if ((event is ModEvent)){
            var modEvent:ModEvent = cast event;
            var name = modEvent.modName;
            var list = modEvents.get(name);
            if (list == null){
                addMod(name);
                list = modEvents.get(name);
            }
            insertSorted(list, modEvent);
        } else
            insertSorted(events, event);
    }

    static function insertSorted<T:BaseEvent>(list:Array<T>, e:T){
        var step = e.executionStep;
        var lo = 0;
        var hi = list.length;
        while (lo < hi){
            var mid = (lo + hi) >>> 1;
            if (list[mid].executionStep <= step) lo = mid + 1;
            else hi = mid;
        }
        var j = lo - 1;
        while (j >= 0 && list[j].executionStep == step){
            if (list[j] == e) return;
            j--;
        }
        list.insert(lo, e);
    }

    static function compact<T:BaseEvent>(list:Array<T>){
        var w = 0;
        for (r in 0...list.length){
            var e = list[r];
            if (!e.finished){
                if (w != r) list[w] = e;
                w++;
            }
        }
        list.resize(w);
    }

    public function update(step:Float){
        if (pending.length > 0) flushPending();
        updating = true;

        for (schedule in schedules){
            if (schedule.length == 0) continue;

            var removed = false;
            var i = 0;
            while (i < schedule.length){
                var event = schedule[i];
                i++;
                if (event.finished){ removed = true; continue; }
                if (event.ignoreExecution) continue;

                if (step >= event.executionStep){
                    event.run(step);
                    if (event.finished) removed = true;
                } else
                    break;
            }
            if (removed) compact(schedule);
        }

        var removedEvents = false;
        var k = 0;
        while (k < events.length){
            var event = events[k];
            k++;
            if (event.finished){ removedEvents = true; continue; }
            if (event.ignoreExecution) continue;

            if (step >= event.executionStep){
                event.run(step);
                if (event.finished) removedEvents = true;
            } else
                break;
        }
        if (removedEvents) compact(events);

        updating = false;
        if (pending.length > 0) flushPending();
    }

    function flushPending(){
        updating = false;
        var list = pending;
        pending = [];
        for (e in list) insertEvent(e);
    }
}