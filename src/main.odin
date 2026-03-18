package silicon

import "core:log"

main :: proc() {
	context.logger = log.create_console_logger()
	run_engine()
}
