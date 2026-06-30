import Foundation

enum Categories {
    /// extension (lowercased, no dot) -> folder name
    static let builtin: [String: String] = {
        var m: [String: String] = [:]
        func add(_ folder: String, _ exts: [String]) {
            for e in exts { m[e] = folder }
        }
        add("Images",        ["png","jpg","jpeg","gif","svg","webp","heic","heif","bmp","tiff","tif","ico","avif"])
        add("Archives",      ["zip","7z","rar","tar","gz","tgz","bz2","xz"])
        add("Documents",     ["pdf","doc","docx","txt","rtf","odt","pages","md"])
        add("Spreadsheets",  ["xls","xlsx","csv","tsv","numbers"])
        add("Presentations", ["ppt","pptx","key"])
        add("Audio",         ["mp3","wav","flac","aac","m4a","ogg","opus"])
        add("Video",         ["mp4","mov","avi","mkv","webm","m4v","wmv","flv"])
        add("Code",          ["js","ts","jsx","tsx","py","java","c","cpp","h","cs","go","rs","rb","php","html","css","json","xml","yaml","yml","sh","sql","dart","kt","swift"])
        add("Installers",    ["dmg","pkg"])
        add("Fonts",         ["ttf","otf","woff","woff2"])
        add("Ebooks",        ["epub","mobi","azw3"])
        return m
    }()

    /// Ordered list of category names for display.
    static let names: [String] = [
        "Images","Archives","Documents","Spreadsheets","Presentations",
        "Audio","Video","Code","Installers","Fonts","Ebooks"
    ]
}
