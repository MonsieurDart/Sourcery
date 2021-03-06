import Quick
import Nimble
@testable import Sourcery
@testable import SourceryRuntime

class FileParserAttributesSpec: QuickSpec {
    override func spec() {

        describe("FileParser") {

            guard let sut: FileParser = try? FileParser(contents: "") else { return fail() }

            func parse(_ code: String) -> [Type] {
                guard let parserResult = try? FileParser(contents: code).parse() else { fail(); return [] }
                return Composer().uniqueTypes(parserResult)
            }

            it("extracts type attributes") {
                expect(sut.parseTypeAttributes("@autoclosure @convention(swift) @escaping (@escaping ()->())->()"))
                    .to(equal([
                        "escaping": Attribute(name: "escaping"),
                        "convention": Attribute(name: "convention", arguments: ["swift": NSNumber(value: true)], description: "@convention(swift)"),
                        "autoclosure": Attribute(name: "autoclosure")
                        ]))
            }

            context("given attribute with arguments") {
                it("extracts attribute arguments with no values") {
                    expect(sut.parseTypeAttributes("@convention(swift) (@escaping ()->())->()"))
                        .to(equal([
                            "convention": Attribute(name: "convention", arguments: ["swift": NSNumber(value: true)], description: "@convention(swift)")
                            ]))
                }

                it("extracts attribute arguments with values") {
                    expect(sut.parseTypeAttributes("@available(*, unavailable, renamed: \"Use MyRenamedProtocol\")"))
                        .to(equal([
                            "available": Attribute(name: "available", arguments: [
                                "unavailable": NSNumber(value: true),
                                "renamed": "Use MyRenamedProtocol" as NSString
                                ], description: "@available(*, unavailable, renamed: \"Use MyRenamedProtocol\")")
                            ]))

                    expect(sut.parseTypeAttributes("@available(iOS 10.0, macOS 10.12, *)"))
                        .to(equal([
                            "available": Attribute(name: "available", arguments: [
                                "iOS_10.0": NSNumber(value: true),
                                "macOS_10.12": NSNumber(value: true)
                                ], description: "@available(iOS 10.0, macOS 10.12, *)")
                            ]))

                }
            }

            it("extracts method attributes") {
                expect(parse("class Foo { @discardableResult\n@objc(some)\nfunc some() {} }").first?.methods.first?.attributes).to(equal([
                    "discardableResult": Attribute(name: "discardableResult"),
                    "objc": Attribute(name: "objc", arguments: ["some": NSNumber(value: true)], description: "@objc(some)")
                    ]))

                expect(parse("class Foo { @nonobjc convenience required init() {} }").first?.initializers.first?.attributes).to(equal([
                    "nonobjc": Attribute(name: "nonobjc"),
                    "convenience": Attribute(name: "convenience", description: "convenience"),
                    "required": Attribute(name: "required", description: "required")
                    ]))
            }

            it("extracts method parameter attributes") {
                expect(parse("class Foo { func some(param: @escaping ()->()) {} }").first?.methods.first?.parameters.first?.typeAttributes).to(equal([
                    "escaping": Attribute(name: "escaping")
                    ]))
            }

            it("extracts variable attributes") {
                expect(parse("class Foo { @NSCopying @objc(objcName:) var name: String }").first?.variables.first?.attributes).to(equal([
                    "NSCopying": Attribute(name: "NSCopying"),
                    "objc": Attribute(name: "objc", arguments: ["objcName:": NSNumber(value: true)], description: "@objc(objcName:)")
                    ]))
            }

            it("extracts type attributes") {
                expect(parse("@nonobjc class Foo {}").first?.attributes).to(equal([
                    "nonobjc": Attribute(name: "nonobjc")
                ]))
            }

        }
    }
}
