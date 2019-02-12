package testadapter.data;

import haxe.Timer;
import haxe.io.Path;
#if (sys || nodejs)
import haxe.Json;
import json2object.JsonParser;
import sys.FileSystem;
import sys.io.File;
#end
import testadapter.data.Data;

class TestResults {
	static inline var ROOT_SUITE_NAME:String = "root";

	var baseFolder:String;
	var fileName:String;
	var positions:TestPositions;
	var suiteResults:TestSuiteResults;

	public function new(baseFolder:String) {
		this.baseFolder = baseFolder;
		positions = TestPositions.load(baseFolder);
		fileName = getFileName(baseFolder);
		init();
	}

	public function add(className:String, name:String, executionTime:Float = 0, state:TestState, ?message:String, ?errorLine:Int) {
		var pos = positions.get(className, name);
		var line:Null<Int> = null;
		if (pos != null) {
			line = pos.line;
		}
		function makeTest():TestMethodResults {
			return {
				name: name,
				executionTime: executionTime,
				state: state,
				message: message,
				timestamp: Timer.stamp(),
				line: line,
				errorLine: errorLine
			}
		}
		for (data in suiteResults.classes) {
			if (data.name == className) {
				data.methods = data.methods.filter(function(results) return results.name != name);
				data.methods.push(makeTest());
				save();
				return;
			}
		}
		suiteResults.classes.push({
			name: className,
			methods: [makeTest()],
			pos: positions.get(className, null)
		});
		save();
	}

	function init() {
		#if (nodejs || sys)
		if (!FileSystem.exists(fileName)) {
			FileSystem.createDirectory(Data.FOLDER);
			suiteResults = {name: ROOT_SUITE_NAME, classes: []};
			return;
		}
		#end
		suiteResults = load(baseFolder);
	}

	public function save() {
		#if (sys || nodejs)
		File.saveContent(fileName, Json.stringify(suiteResults, null, "\t"));
		#end
	}

	public static function load(?baseFolder:String):TestSuiteResults {
		#if (sys || nodejs)
		var dataFile:String = getFileName(baseFolder);
		if (!FileSystem.exists(dataFile)) {
			return {name: ROOT_SUITE_NAME, classes: []};
		}
		var content:String = File.getContent(dataFile);

		var parser = new JsonParser<TestSuiteResults>();
		return parser.fromJson(content, dataFile);
		#else
		return {name: ROOT_SUITE_NAME, classes: []};
		#end
	}

	public static function getFileName(?baseFolder:String):String {
		return Path.join([baseFolder, Data.FOLDER, "results.json"]);
	}
}