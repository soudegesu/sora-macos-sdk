import Foundation
import SystemConfiguration

/// :nodoc:
func currentMachineName() -> String {
    let machineKey = "hw.machine"
    let machineKeyPtr = UnsafeMutableBufferPointer<Int8>
        .allocate(capacity: machineKey.utf8CString.count)
    _ = machineKeyPtr.initialize(from: machineKey.utf8CString)
    var machineNameLen = 0
    sysctlbyname(machineKeyPtr.baseAddress!, nil, &machineNameLen, nil, 0)
    let machineNamePtr = UnsafeMutableBufferPointer<Int8>
        .allocate(capacity: machineNameLen)
    sysctlbyname(machineKeyPtr.baseAddress!,
                 machineNamePtr.baseAddress!,
                 &machineNameLen, nil, 0)
    let machineName = String.init(cString: machineNamePtr.baseAddress!)
    machineKeyPtr.deallocate()
    machineNamePtr.deallocate()
    return machineName
}

/// :nodoc:
public struct DeviceInfo {
    public static var current: DeviceInfo = DeviceInfo(machineName: currentMachineName())

    @available(*, unavailable, message: "model は廃止されました。")
    public let model: String = ""
    public let machineName: String

    public var description: String {
        "\(machineName)"
    }

    init(machineName: String) {
        self.machineName = machineName
    }
}
