import Foundation
import OSLog

/// A provider class that handles API operations related to team agents.
///
/// This class provides functionality to fetch and list team agents from the aiXplain platform.
public final class TeamAgentProvider {
    
    // MARK: - Properties
    
    /// A logger instance for recording events and debugging information.
    private let logger = Logger(subsystem: "AiXplainKit", category: "AgentProvider")
    
    /// The networking service used to make API calls.
    var networking = Networking()
    
    // MARK: - Initializers
    
    /// Initializes a new instance of `TeamAgentProvider`.
    public init() {
        self.networking = Networking()
    }
    
    /// Internal initializer for testing or dependency injection purposes.
    ///
    /// - Parameter networking: A pre-configured `Networking` instance.
    internal init(networking: Networking) {
        self.networking = networking
    }
    
    /// Retrieves a specific team agent by its ID.
    ///
    /// - Parameter teamAgentID: The unique identifier of the team agent to retrieve.
    /// - Returns: A ``TeamAgent`` instance containing the retrieved team agent's information.
    /// - Throws: Various errors that might occur during the retrieval process:
    ///   - ``AgentsError/missingBackendURL``: If the backend URL is not configured
    ///   - ``AgentsError/invalidURL``: If the constructed URL is invalid
    ///   - ``NetworkingError/invalidStatusCode``: If the server responds with a non-200 status code
    ///   - `DecodingError`: If there's an error decoding the server response
    public func get(_ teamAgentID:String) async throws -> TeamAgent {
        
        let headers: [String: String] = try networking.buildHeader()

        guard let url = APIKeyManager.shared.BACKEND_URL else {
            throw AgentsError.missingBackendURL
        }

        let endpoint = Networking.Endpoint.agentCommunities(agentIdentifier: teamAgentID)
        guard let url = URL(string: url.absoluteString + endpoint.path) else {
            throw AgentsError.invalidURL(url: url.absoluteString + endpoint.path)
        }

        let response = try await networking.get(url: url, headers: headers)

        if let httpUrlResponse = response.1 as? HTTPURLResponse,
           httpUrlResponse.statusCode != 200 {
            throw NetworkingError.invalidStatusCode(statusCode: httpUrlResponse.statusCode)
        }

        do {
            logger.debug("\(String(data: response.0, encoding: .utf8)!)")
            let fetchedTeamAgent = try JSONDecoder().decode(TeamAgent.self, from: response.0)
            logger.info("\(fetchedTeamAgent.name) fetched")
            return fetchedTeamAgent
        } catch {
            logger.error("\(String(describing: error))")
            throw error
        }
    }
    
    /// Retrieves a list of all available team agents.
    ///
    /// - Returns: An array of ``TeamAgent`` instances representing all available team agents.
    /// - Throws: Various errors that might occur during the retrieval process:
    ///   - ``AgentsError/missingBackendURL``: If the backend URL is not configured
    ///   - ``AgentsError/invalidURL``: If the constructed URL is invalid
    ///   - ``NetworkingError/invalidStatusCode``: If the server responds with a non-200 status code
    ///   - `DecodingError`: If there's an error decoding the server response
    public func list() async throws -> [TeamAgent] {
        let headers: [String: String] = try networking.buildHeader()
        
        guard let url = APIKeyManager.shared.BACKEND_URL else {
            throw AgentsError.missingBackendURL
        }
        
        let endpoint = Networking.Endpoint.paginateTeamAgents
        guard let url = URL(string: url.absoluteString + endpoint.path) else {
            throw AgentsError.invalidURL(url: url.absoluteString + endpoint.path)
        }

        let response = try await networking.get(url: url, headers: headers)
        
        if let httpUrlResponse = response.1 as? HTTPURLResponse,
           httpUrlResponse.statusCode != 200 {
            throw NetworkingError.invalidStatusCode(statusCode: httpUrlResponse.statusCode)
        }

        do {
            logger.debug("\(String(data: response.0, encoding: .utf8)!)")
            let fetchedTeamAgents:[TeamAgent] = try JSONDecoder().decode([TeamAgent].self, from: response.0)
           
            logger.info("\(fetchedTeamAgents.count) fetched")
            return fetchedTeamAgents
        } catch {
            logger.error("\(String(describing: error))")
            throw error
        }
    }
}
