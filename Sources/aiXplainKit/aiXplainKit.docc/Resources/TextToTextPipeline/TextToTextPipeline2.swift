import Foundation
import aiXplainKit

let pipeline = try! await PipelineProvider().get(textToTextPipelineID)

let pipelineOutput = try! await pipeline.run("The primary duty of an exception handler is to get the error out of the lap of the programmer and into the surprised face of the user.")
