//
//  WebArchiver.swift
//  Twibu
//
//  Created by abeyuya on 2019/08/10.
//  Copyright © 2019 abeyuya. All rights reserved.
//

import Foundation
import WebKit
import Embedded

final class WebArchiver: NSObject {
    static let shared = WebArchiver()
    private override init() {}

    private var completion: ((Result<Void>) -> Void)!
    private var bookmarkUid: String!

    static func buildLocalFileUrl(bookmarkUid: String) -> URL? {
        let archiveUrl = try? FileManager.default.url(
            for: .cachesDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
            .appendingPathComponent(bookmarkUid)
            .appendingPathExtension("pdf")

        return archiveUrl
    }

    func save(bookmarkUid: String, url: URL, completion: @escaping (Result<Void>) -> Void) {
        if WebArchiver.buildLocalFileUrl(bookmarkUid: bookmarkUid) == nil {
            completion(.failure(TwibuError.webArchiveError("localFileUrlが取得できませんでした")))
            return
        }

        self.completion = completion
        self.bookmarkUid = bookmarkUid

        let webView = WKWebView(
            frame: CGRect(
                x: UIScreen.main.bounds.size.width,
                y: 0,
                width: UIScreen.main.bounds.size.width,
                height: UIScreen.main.bounds.size.height
            )
        )
        webView.isHidden = true
        webView.navigationDelegate = self
        webView.scrollView.zoomScale = UIScreen.main.scale

        Router.shared.addHeadlessWebView(webView: webView)
        webView.load(.init(url: url))
    }

    private func execSave(webView: WKWebView) {
        guard let url = WebArchiver.buildLocalFileUrl(bookmarkUid: bookmarkUid) else {
            completion(.failure(TwibuError.webArchiveError("localFileUrlが取得できませんでした")))
            return
        }
        let d = webView.createPdfFile()

        do {
            try d.write(to: url)
            completion(.success(Void()))
        } catch {
            completion(.failure(TwibuError.webArchiveError(error.localizedDescription)))
        }
    }
}

extension WebArchiver: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        execSave(webView: webView)
    }
}

//
// http://www.swiftdevcenter.com/create-pdf-from-uiview-wkwebview-and-uitableview/
//
private extension WKWebView {
    func createPdfFile() -> NSMutableData {
        let originalBounds = UIScreen.main.bounds
        self.bounds = CGRect(
            x: originalBounds.origin.x,
            y: bounds.origin.y,
            width: originalBounds.size.width,
            height: self.scrollView.contentSize.height
        )
        let pdfPageFrame = CGRect(
            x: 0,
            y: 0,
            width: self.bounds.size.width,
            height: self.scrollView.contentSize.height
        )
        let printPageRenderer = UIPrintPageRenderer()
        printPageRenderer.addPrintFormatter(self.viewPrintFormatter(), startingAtPageAt: 0)
        printPageRenderer.setValue(NSValue(cgRect: pdfPageFrame), forKey: "paperRect")
        printPageRenderer.setValue(NSValue(cgRect: pdfPageFrame), forKey: "printableRect")
        self.bounds = originalBounds
        return printPageRenderer.generatePdfData()
    }
}

private extension UIPrintPageRenderer {
    func generatePdfData() -> NSMutableData {
        let pdfData = NSMutableData()
        UIGraphicsBeginPDFContextToData(pdfData, self.paperRect, nil)
        self.prepare(forDrawingPages: NSMakeRange(0, self.numberOfPages))
        let printRect = UIGraphicsGetPDFContextBounds()
        for pdfPage in 0 ..< self.numberOfPages {
            UIGraphicsBeginPDFPage()
            self.drawPage(at: pdfPage, in: printRect)
        }
        UIGraphicsEndPDFContext();
        return pdfData
    }
}