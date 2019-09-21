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
    enum SaveResult {
        case success
        case failure(TwibuError)
        case progress(Double)
    }

    static func buildLocalFileUrl(bookmarkUid: String) -> URL? {
        let archiveUrl = try? FileManager.default.url(
            for: .documentDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
            .appendingPathComponent(bookmarkUid)
            .appendingPathExtension("pdf")

        return archiveUrl
    }

    static func existLocalFile(bookmarkUid: String) -> Bool {
        if let localFileUrl = WebArchiver.buildLocalFileUrl(bookmarkUid: bookmarkUid),
            FileManager.default.fileExists(atPath: localFileUrl.path) {
            return true
        }
        return false
    }

    static func save(webView: WKWebView, bookmarkUid: String, callback: @escaping (SaveResult) -> Void) {
        guard let localFileUrl = WebArchiver.buildLocalFileUrl(bookmarkUid: bookmarkUid) else {
            callback(.failure(TwibuError.webArchiveError("localFileUrlが取得できませんでした")))
            return
        }

        let d = webView.createPdfFile()

        do {
            try d.write(to: localFileUrl)
            callback(.success)
        } catch {
            callback(.failure(TwibuError.webArchiveError(error.localizedDescription)))
        }
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
