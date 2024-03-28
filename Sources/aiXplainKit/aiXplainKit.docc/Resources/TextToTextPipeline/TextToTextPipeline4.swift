import Foundation
import aiXplainKit

let pipeline = try! await PipelineProvider().get(textToTextPipelineID)

let pipelineOutput = try! await pipeline.run("The primary duty of an exception handler is to get the error out of the lap of the programmer and into the surprised face of the user.")

if let dataArray = json["data"] as? [[String: Any]],
               let dataObject = dataArray.first,
               let segments = dataObject["segments"] as? [[String: Any]],
               let segment = segments.first,
               let details = segment["details"] as? [String: Any],
               let rawData = details["rawData"] as? [String: Any],
               let data = rawData["data"] as? [String: Any],
               let translations = data["translations"] as? [[String: String]],
               let translation = translations.first {

                if let translatedText = translation["translatedText"] {
//                    translatedText = "La tâche principale d'un gestionnaire d'exceptions est d'extraire l'erreur du programmeur et de la faire apparaître sur le visage surpris de l'utilisateur."
                }
            }
