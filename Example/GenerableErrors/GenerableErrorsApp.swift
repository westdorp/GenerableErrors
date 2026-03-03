import GenerableErrors
import SwiftUI

@main
struct GenerableErrorsApp: App {
    @State private var viewModel: ErrorGeneratorViewModel

    init() {
        let session = FoundationModelSession()
        session.prewarmModel()
        let catalogLoader = JSONHTTPErrorCatalogLoader()
        let catalogResult: Result<HTTPErrorCatalog, HTTPErrorCatalogLoadError>
        do {
            catalogResult = .success(try catalogLoader.loadCatalog())
        } catch let loadError as HTTPErrorCatalogLoadError {
            catalogResult = .failure(loadError)
        } catch {
            catalogResult = .failure(.decodingFailed(context: error.localizedDescription))
        }

        self._viewModel = State(
            initialValue: ErrorGeneratorViewModel(
                session: session,
                catalogResult: catalogResult
            )
        )
    }

    var body: some Scene {
        WindowGroup {
            GenerableErrorsView(viewModel: viewModel)
        }
    }
}
