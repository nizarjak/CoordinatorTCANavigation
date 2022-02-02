import Foundation

enum Log {
    static func debug(
        _ message: String = "",
        file: StaticString = #file,
        function: StaticString = #function,
        line: UInt = #line
    ) {
        let fileName = String(file).split(separator: "/").last!
        print("🔨 \(fileName):\(line) > \(function) \(message) ")
    }
}

extension String {
    init(_ staticString: StaticString) {
        self = staticString.withUTF8Buffer {
            String(decoding: $0, as: UTF8.self)
        }
    }
}
