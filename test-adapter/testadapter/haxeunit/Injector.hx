package testadapter.haxeunit;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
import testadapter.data.TestFilter;

using testadapter.PatchTools;
using StringTools;

class Injector {
	public static function buildRunner():Array<Field> {
		var fields = Context.getBuildFields();

		for (field in fields) {
			switch (field.name) {
				case "new":
					field.addInit(macro testResults = new testadapter.data.TestResults($v{Sys.getCwd()}));
				case "run":
					field.name = "__run";
			}
		}

		var extraFields = (macro class {
			var testResults:testadapter.data.TestResults;

			public function run():Bool {
				var success:Bool = __run();
				publishAdapterResults();
				return success;
			}

			@:access(haxe.unit.TestResult)
			function publishAdapterResults() {
				for (r in result.m_tests) {
					var state:testadapter.data.Data.TestState = Failure;
					var errorLine:Null<Int> = null;
					if (r.success) {
						state = Success;
					} else if (r.error != null) {
						if (StringTools.startsWith(r.error, "exception thrown : ")) {
							state = Error;
						}
						if (r.posInfos != null) {
							errorLine = r.posInfos.lineNumber - 1;
						}
					}
					testResults.add(r.classname, r.method, 0, state, r.error, errorLine);
				}
				testResults.save();
			}
		}).fields;
		return fields.concat(extraFields);
	}

	public static function buildCase():Array<Field> {
		var fields = Context.getBuildFields();
		for (field in fields) {
			switch (field.kind) {
				case FFun(_) if (field.name.startsWith("test")):
					var clazz = Context.getLocalClass().get();
					var dotPath = clazz.pack.concat([clazz.name]).join(".");
					if (!TestFilter.shouldRunTest(Macro.filters, dotPath, field.name)) {
						field.name = "disabled_" + field.name;
					}
				case _:
			}
		}
		return fields;
	}
}
#end
