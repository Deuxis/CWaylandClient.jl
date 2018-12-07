"""
    CWaylandClientCore

Wrapper around libwayland-client.

Implemented differently:
- naming and calling convention - Julia-lised the functions to have shorter names and be distinguished by different object overloads. Eg. `wl_display_disconnect(struct wl_display *display)` -> `disconnect(display::Ptr{WlDisplay})`
- array marshalling functions - their library implementations require C unions and are more trouble then they're worth. Simply made them splat the array and call the non-array versions.

Not implemented:
- log handler
"""
module CWaylandClientCore

abstract type WlDisplay end
abstract type WlProxy end
abstract type WlProxyReal <: WlProxy end
abstract type WlProxyWrapper <: WlProxy end
abstract type WlEventQueue end

# Display
"Connect to the default display."
function connect()
    ccall((:wl_display_connect, "libwayland-client"), Ptr{WlDisplay}, (Ptr{Cvoid},), C_NULL)
end
"Connect to a named display."
function connect(path::String)
    ccall((:wl_display_connect, "libwayland-client"), Ptr{WlDisplay}, (Cstring,), path)
end
"Connect to a display via a file descriptor."
function connect(fd::RawFD)
    ccall((:wl_display_connect_to_fd, "libwayland-client"), Ptr{WlDisplay}, (RawFD,), fd)
end
"Disconnect from `display`."
function disconnect!(display::Ptr{WlDisplay})
    ccall((:wl_display_disconnect, "libwayland-client"), Cvoid, (Ptr{WlDisplay},), display)
end
"Get `display`'s file descriptor."
function getfd(display::Ptr{WlDisplay})
    ccall((:wl_display_get_fd, "libwayland-client"), RawFD, (Ptr{WlDisplay},), display)
end
"Get a local error."
function geterror(display::Ptr{WlDisplay})
    ccall((:wl_display_get_error, "libwayland-client"), Cint, (Ptr{WlDisplay},), display)
end
"Get a remote error."
function geterror(display::Ptr{WlDisplay}, interface::Ref{WlInterface}, id::Integer)
    ccall((:wl_display_get_protocol_error, "libwayland-client"), UInt32,
    (Ptr{WlDisplay}, Ref{WlInterface}, UInt32),
    display, interface, id)
end
"Flush all requests to display."
function flush(display::Ptr{WlDisplay})
    ccall((:wl_display_flush, "libwayland-client"), Cint, (Ptr{WlDisplay},), display)
end
"Block until all requests have been processed by `display`."
function roundtrip(display::Ptr{WlDisplay})
    ccall((:wl_display_roundtrip, "libwayland-client"), Cint, (Ptr{WlDisplay},), display)
end
"Block until all requests on `queue` have been processed by `display`."
function roundtrip(display::Ptr{WlDisplay}, queue::Ptr{WlEventQueue})
    ccall((:wl_display_roundtrip_queue, "libwayland-client"), Cint,
    (Ptr{WlDisplay}, Ptr{WlEventQueue}),
    display, queue))
end
"Start preparing all events on `display` for reading."
function prepare_read(display::Ptr{WlDisplay})
    ccall((:wl_display_prepare_read, "libwayland-client"), Cint, (Ptr{WlDisplay},), display)
end
"Start preparing all events on `display`'s' `queue` for reading."
function prepare_read(display::Ptr{WlDisplay}, queue::Ptr{WlEventQueue})
    ccall((:wl_display_prepare_read_queue, "libwayland-client"), Cint,
    (Ptr{WlDisplay}, Ptr{WlEventQueue}),
    display, queue))
end
"Cancel the prepared read on `display`."
function cancel_read(display::Ptr{WlDisplay})
    ccall((:wl_display_cancel_read, "libwayland-client"), Cvoid, (Ptr{WlDisplay},), display)
end
"Read the prepared events on `display`."
function read_events(display::Ptr{WlDisplay})
    ccall((:wl_display_read_events, "libwayland-client"), Cint, (Ptr{WlDisplay},), display)
end
"Dispatch event handlers on all events for `display`. Block if there are none."
function dispatch(display::Ptr{WlDisplay})
    ccall((:wl_display_dispatch, "libwayland-client"), Cint, (Ptr{WlDisplay},), display)
end
"Dispatch event handlers on all events for `display`'s `queue`. Block if there are none."
function dispatch(display::Ptr{WlDisplay}, queue::Ptr{WlEventQueue})
    ccall((:wl_display_dispatch_queue, "libwayland-client"), Cint,
    (Ptr{WlDisplay}, Ptr{WlEventQueue}),
    display, queue)
end
"Dispatch event handlers on all events for `display`. Skip if there are none."
function dispatch_pending(display::Ptr{WlDisplay})
    ccall((:wl_display_dispatch_pending, "libwayland-client"), Cint, (Ptr{WlDisplay},), display)
end
"Dispatch event handlers on all events for `display`'s `queue`. Skip if there are none."
function dispatch_pending(display::Ptr{WlDisplay}, queue::Ptr{WlEventQueue})
    ccall((:wl_display_dispatch_queue_pending, "libwayland-client"), Cint,
    (Ptr{WlDisplay}, Ptr{WlEventQueue}),
    display, queue)
end
# Event queue
"Create a `WlEventQueue`."
function create_queue(display::Ptr{WlDisplay})
    ccall((:wl_event_queue_destroy, "libwayland-client"), Ptr{WlEventQueue}, (Ptr{WlDisplay},), display)
end
"Destroy a `WlEventQueue`."
function destroy!(queue::Ptr{WlEventQueue})
    ccall((:wl_event_queue_destroy, "libwayland-client"), Cvoid, (Ptr{WlEventQueue},), queue)
end
# Proxy
"Create a `WlProxy`."
function create_proxy(factory::Ptr{<: WlProxy}, interface::Ref{WlInterface})
    ret = ccall((:wl_proxy_create, "libwayland-client"), Ptr{WlProxy},
    (Ptr{WlProxy}, Ref{WlInterface}),
    factory, interface)
    if ret == C_NULL
        error("Failure creating proxy.")
    else
        return ret
    end
end
"Destroy a `WlProxy`."
function destroy!(proxy::Ptr{WlProxyReal})
    ccall((:wl_proxy_destroy, "libwayland-client"), Cvoid, (Ptr{WlProxy},), proxy)
end
"Get `proxy`'s version."
function getversion(proxy::Ptr{<: WlProxy})
    ccall((:wl_proxy_get_version, "libwayland-client"), UInt32, (Ptr{WlProxy},), proxy)
end
"Get `proxy`'s ID."
function getid(proxy::Ptr{<: WlProxy})
    ccall((:wl_proxy_get_id, "libwayland-client"), UInt32, (Ptr{WlProxy},), proxy)
end
"Get `proxy`'s class."
function getclass(proxy::Ptr{<: WlProxy})
    ccall((:wl_proxy_get_class, "libwayland-client"), Cstring, (Ptr{WlProxy},), proxy)
end
"Set `proxy`'s event queue."
function setqueue!(proxy::Ptr{<: WlProxy}, queue::Ptr{WlEventQueue})
    ccall((:wl_proxy_set_queue, "libwayland-client"), Cvoid, (Ptr{WlProxy},), proxy)
end
# Proxy wrapper
"Create a `WlProxyWrapper` for `proxy`."
function create_wrapper(proxy::Ptr{<: WlProxy})
    wrapper = ccall((:wl_proxy_create_wrapper, "libwayland-client"), Ptr{WlProxyWrapper}, (Ptr{<: WlProxy},), proxy)
    if wrapper == C_NULL
        error("Failed to create a wrapper.")
    else
        return wrapper
    end
end
"Destroy a `WlProxyWrapper`."
function destroy!(wrapper::Ptr{WlProxyWrapper})
    ccall((:wl_proxy_wrapper_destroy, "libwayland-client"), Cvoid, (Ptr{WlProxyWrapper},), wrapper)
end
# Marshalling messages
"Marshal a message."
function marshal(proxy::Ptr{<: WlProxy}, opcode::Integer, args...)
    ccall((:wl_proxy_marshal, "libwayland-client"), Cvoid,
    (Ptr{WlProxy}, UInt32, Any...),
    proxy, opcode, args...)
end
marshal(proxy::Ptr{<: WlProxy}, opcode::Integer, args::Vector) = marshal(proxy, opcode, args...)
"Marshal a message, which may be a constructor."
function marshal_constructor(proxy::Ptr{<: WlProxy}, opcode::Integer, interface::Ref{WlInterface}, args...)
    ccall((:wl_proxy_marshal_constructor, "libwayland-client"), Ptr{WlProxy},
    (Ptr{WlProxy}, UInt32, Ref{WlInterface}, Any...),
    proxy, opcode, interface, args...)
end
marshal_constructor(proxy::Ptr{<: WlProxy}, opcode::Integer, args::Vector, interface::Ref{WlInterface}) = marshal_constructor(proxy, opcode, interface, args...)
"Versioned [`marshal_constructor`](@ref)"
function marshal_constructor_versioned(proxy::Ptr{<: WlProxy}, opcode::Integer, interface::Ref{WlInterface}, version::Integer, args...)
    ccall((:wl_proxy_marshal_constructor_versioned, "libwayland-client"), Ptr{WlProxy},
    (Ptr{WlProxy}, UInt32, Ref{WlInterface}, UInt32, Any...),
    proxy, opcode, interface, version, args...)
end
marshal_constructor_versioned(proxy::Ptr{<: WlProxy}, opcode::Integer, args::Vector, interface::Ref{WlInterface}, version::Integer) = marshal_constructor_versioned(proxy, opcode, interface, args...)
# Listening
"Attach listener struct to `proxy`, overriding the previous."
function addlistener!(proxy::Ptr{WlProxyReal}, implementation::Ref, data::Ref)
    ccall((:wl_proxy_add_listener, "libwayland-client"), Cint,
    (Ptr{WlProxy}, Ref, Ref),
    proxy, implementation, data)
end
function adddispatcher!(proxy::Ptr{WlProxyReal}, dispatcher_func::CFunction, dispatcher_data::Ref, data::Ref)
    ccall((:wl_proxy_add_dispatcher, "libwayland-client"), Cint,
    (Ptr{WlProxy}, CFunction, Ref, Ref),
    proxy, dispatcher_func, dispatcher_data, data)
end
"Get the `proxy`'s listener."
function getlistener(proxy::Ptr{WlProxyReal})
    ccall((:wl_proxy_get_listener, "libwayland-client"), Ptr, (Ptr{WlProxy},), proxy)
end
# User data (the same data which is added to a proxy when adding listeners and is supplied to the listeners)
"Set `proxy`'s user data, overriding the previous."
function setuserdata!(proxy::Ptr{WlProxyReal}, data::Ref)
    ccall((:wl_proxy_set_user_data, "libwayland-client"), Cvoid,
    (Ptr{WlProxy}, Ref),
    proxy, data)
end
"Get `proxy`'s user data."
function getuserdata(proxy::Ptr{WlProxyReal})
    ccall((:wl_proxy_get_user_data, "libwayland-client"), Ref, (Ptr{WlProxy},), proxy)
end

end # module
