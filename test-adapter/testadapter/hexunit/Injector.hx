package testadapter.hexunit;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;

using testadapter.PatchTools;

class Injector {
	public static function buildCore():Array<Field> {
		var fields = Context.getBuildFields();
		for (field in fields) {
			switch (field.name) {
				case "new":
					field.addInit(macro {
						addListener(new testadapter.hexunit.Notifier($v{Sys.getCwd()}));
					});
				case "run":
					field.name = "__" + field.name;
				case _:
			}
		}
		var extraFields = (macro class {
			public function run() {
				if ($v{Macro.filters}.length > 0) {
					var filteredClassDescriptors:Array<hex.unittest.description.ClassDescriptor> = [];

					for (desc in _classDescriptors) {
						if ($v{Macro.filters}.indexOf(desc.className) >= 0) {
							filteredClassDescriptors.push(desc);
							continue;
						}
						var filteredMethodDescriptors:Array<hex.unittest.description.MethodDescriptor> = [];
						for (method in desc.methodDescriptors) {
							if ($v{Macro.filters}.indexOf(desc.className + "." + method.methodName) >= 0) {
								filteredMethodDescriptors.push(method);
							}
						}
						if (filteredMethodDescriptors.length > 0) {
							desc.methodDescriptors = filteredMethodDescriptors;
							filteredClassDescriptors.push(desc);
						}
					}
					_classDescriptors = filteredClassDescriptors;
				}
				__run();
			}
		}).fields;
		return fields.concat(extraFields);
	}
}
#end
