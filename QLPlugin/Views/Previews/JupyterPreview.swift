import Foundation
import os.log
import SwiftExec

class JupyterPreview: Preview {
	private let chromaStylesheetURL = Bundle.main.url(
		forResource: "shared-chroma",
		withExtension: "css"
	)
	private let katexAutoRenderScriptURL = Bundle.main.url(
		forResource: "jupyter-katex-auto-render.min",
		withExtension: "js"
	)
	private let katexScriptURL = Bundle.main.url(
		forResource: "jupyter-katex.min",
		withExtension: "js"
	)
	private let katexStylesheetURL = Bundle.main.url(
		forResource: "jupyter-katex.min",
		withExtension: "css"
	)
	private let mainStylesheetURL = Bundle.main.url(
		forResource: "jupyter-main",
		withExtension: "css"
	)
	private let nbtohtmlBinaryURL = Bundle.main.url(forAuxiliaryExecutable: "nbtohtml-v0.4.0")

	required init() {}

	private func getHTML(filePath: String) throws -> String {
		do {
			let result = try exec(
				program: nbtohtmlBinaryURL!.path,
				arguments: ["convert", filePath]
			)
			return result.stdout ?? ""
		} catch {
			os_log(
				"Could not generate Jupyter Notebook HTML using nbtohtml: %{public}s",
				log: Log.render,
				type: .error,
				error.localizedDescription
			)
			throw error
		}
	}

	private func getStylesheets() -> [Stylesheet] {
		var stylesheets = [Stylesheet]()

		// Main Jupyter stylesheet (overrides and additions for nbtohtml stylesheet)
		if let mainStylesheetURL = mainStylesheetURL {
			stylesheets.append(Stylesheet(url: mainStylesheetURL))
		} else {
			os_log("Could not find main Jupyter stylesheet", log: Log.render, type: .error)
		}

		// Chroma stylesheet (for code syntax highlighting)
		if let chromaStylesheetURL = chromaStylesheetURL {
			stylesheets.append(Stylesheet(url: chromaStylesheetURL))
		} else {
			os_log("Could not find Chroma stylesheet", log: Log.render, type: .error)
		}

		// KaTeX stylesheet (for rendering LaTeX math)
		if let katexStylesheetURL = katexStylesheetURL {
			stylesheets.append(Stylesheet(url: katexStylesheetURL))
		} else {
			os_log("Could not find KaTeX stylesheet", log: Log.render, type: .error)
		}

		return stylesheets
	}

	private func getScripts() -> [Script] {
		var scripts = [Script]()

		// KaTeX library (for rendering LaTeX math)
		if let katexScriptURL = katexScriptURL {
			scripts.append(Script(url: katexScriptURL))
		} else {
			os_log("Could not find KaTeX script", log: Log.render, type: .error)
		}

		// KaTeX auto-renderer (finds LaTeX math ond the page and calls KaTeX on it)
		if let katexAutoRenderScriptURL = katexAutoRenderScriptURL {
			scripts.append(Script(url: katexAutoRenderScriptURL))
		} else {
			os_log("Could not find KaTeX auto-render script", log: Log.render, type: .error)
		}

		// Main script (calls the KaTeX auto-renderer)
		scripts.append(Script(content: "renderMathInElement(document.body);"))

		return scripts
	}

	func createPreviewVC(file: File) throws -> PreviewVC {
		WebPreviewVC(
			html: try getHTML(filePath: file.path),
			stylesheets: getStylesheets(),
			scripts: getScripts()
		)
	}
}
