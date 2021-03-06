package testadapter.tinktestrunner;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;

class Injector {
	public static function buildRunner():Array<Field> {
		var fields = Context.getBuildFields();
		for (field in fields) {
			switch (field.name) {
				case "run", "runCase":
					field.name = "__" + field.name;
				case _:
			}
		}

		var extraFields = (macro class {
			static var adapterReporter:testadapter.tinktestrunner.Reporter;
			public static function run(batch:Batch, ?reporter:Reporter, ?timers:TimerManager):Future<BatchResult> {
				if (!testadapter.data.TestFilter.hasFilters($v{Macro.filters})) {
					testadapter.data.TestResults.clear($v{Sys.getCwd()});
				}
				adapterReporter = new testadapter.tinktestrunner.Reporter($v{Sys.getCwd()}, reporter);
				return __run(batch, adapterReporter, timers);
			}
			static function runCase(caze:Case, suite:Suite, reporter:Reporter, timers:TimerManager):Future<CaseResult> {
				var clazz:Null<String> = adapterReporter.testResults.positions.resolveClassName(caze.pos.fileName, caze.pos.lineNumber - 1);
				if (clazz == null) {
					clazz = suite.info.name;
				}
				if (!testadapter.data.TestFilter.shouldRunTest($v{Macro.filters}, clazz, caze.info.name)) {
					return Future.async(function(cb) {
						cb({
							info: caze.info,
							results: Outcome.Success([])
						});
					});
				}
				return __runCase(caze, suite, reporter, timers);
			}
		}).fields;
		return fields.concat(extraFields);
	}
}
#end
