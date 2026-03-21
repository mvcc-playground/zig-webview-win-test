const std = @import("std");

pub const GetFullNameResult = union(enum) {
    text: []const u8,
    @"error": struct {
        message: []const u8,
    },
};

pub fn getLastName(lastName: []const u8) []const u8 {
    return lastName;
}

pub fn getFullName(lastName: []const u8) GetFullNameResult {
    if (std.mem.eql(u8, lastName, "xxx")) {
        return .{
            .@"error" = .{
                .message = "lastName 'xxx' is blocked",
            },
        };
    }

    if (std.mem.eql(u8, lastName, "silva")) {
        return .{ .text = "Mathe Silva" };
    }

    return .{ .text = lastName };
}

pub const commands = .{
    .getLastName = getLastName,
    .getFullName = getFullName,
};

pub const command_meta = .{
    .getLastName = .{
        .arg_names = .{"lastName"},
    },
    .getFullName = .{
        .arg_names = .{"lastName"},
    },
};
