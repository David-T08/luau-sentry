local RunService = game:GetService("RunService")
local sdkInfo = require(script.Parent.info)

local envelopeEventTypes = {
	event = {event_id = { required = true, value = "" }}
}

type Level = 'fatal' | 'error' | 'warning' | 'info' | 'debug'

export type Options = {
	dsn: string,

	-- The /store endpoint is marked as deprecated, but the use of /envelope requires you to use a Relay (https://docs.sentry.io/product/relay/)
	-- However, relays must be self hosted.
	-- Set this to true if your DSN points to a relay that supports envelopes, otherwise set to false/nil
	supportsEnvelopes: boolean?,
	-- 0-1, Determines how many events get sent (0.5 -> 50%)
	sampleRate: number?,

	integrations: any?,
	defaultIntegrations: any?,

	maxBreadcrumbs: number?,

	-- Allows the capturing of environment variables using getfenv()
	-- Only use this if needed, as getfenv() disables Luau's performance optimizations
	captureEnvironment: boolean?
}

-- https://develop.sentry.dev/sdk/data-model/event-payloads/breadcrumbs/
export type Breadcrumb = {
	-- https://develop.sentry.dev/sdk/data-model/event-payloads/breadcrumbs/#breadcrumb-types
	type: string,
	category: string,

	message: string,
	level: string,

	timestamp: number,
	data: {[string]: any}
}

-- export type Envelope = {
-- 	Items: {Item}
-- }

type StackFrame = {
	filename: string,
	["function"]: string,
	lineno: number,
	
	-- this might stay? IDK, need to try it out
	module: string,
}

-- https://develop.sentry.dev/sdk/data-model/event-payloads/stacktrace/
export type Stacktrace = {
	frames: {StackFrame}
}

-- https://develop.sentry.dev/sdk/data-model/event-payloads/exception/
export type Exception = {
	type: string,
	value: string,

	module: string,
	-- Determining whether this is needed or not?
	-- Is it important to know what thread it was?
	thread_id: string,
	stacktrace: Stacktrace
}

-- https://develop.sentry.dev/sdk/data-model/event-payloads/request/
export type Request = {
	method: string,
	url: string,
	
	-- ["content-type", "application/json"]
	headers: { {string} },
}

type DeviceContext = {
	name: string,
	orientation: string,
	screen_resolution: string,

	-- This might be possible to get?
	-- May be removed
	memory_size: number, 
	usable_memory: number,
	low_memory: boolean,

	-- I'm thinking os.clock() for this?
	boot_time: number,

	device_type: string,
	supports_vibration: boolean,
	supports_accelerometer: boolean,
	supports_gyroscope: boolean,
}

type CultureContext = {
	timezone: string,
	locale: string
}

-- https://develop.sentry.dev/sdk/data-model/event-payloads/message/
export type Message = {
	formatted: string
}

-- https://develop.sentry.dev/sdk/data-model/event-payloads/user/
export type User = {
	id: string,
	username: string,

	geo: {
		["country-code"]: string,
		region: string
	}
}

-- Base event template
local Event = {
	event_id = "",
	timestamp = 0,
	platform = "other",

	level = "error",
	logger = if RunService:IsServer() then "server" else "client",
	environment = if RunService:IsStudio() then "development" else "production",

	extra = {},
	tags = {},

	sdk = {
		name = sdkInfo.name,
		version = sdkInfo.version,
	},
} :: Event

-- https://develop.sentry.dev/sdk/data-model/event-payloads/
export type Event = {
	event_id: string,
	timestamp: number,
	platform: 'other',

	level: Level,
	logger: string | 'server' | 'client',
	environment: string | 'production' | 'development',

	transaction: string?,
	fingerprint: {string}?,
	release: string?,
	dist: string?,

	extra: {[string]: any}?,
	tags: {[string]: any}?,

	user: User?,
	breadcrumbs: {Breadcrumb}?,
	message: Message?,
	exception: {Exception}?,
	contexts: {
		device: DeviceContext?,
		culture: CultureContext?
	}?,

	-- Autofilled
	sdk: {
		name: string,
		version: string
	}
}

export type EventProcessor = (event: Event) -> (Event?)

export type _sentry_impl = {
	__index: _sentry_impl,

	init: (options: Options, name: string) -> Sentry,
	get: (name: string) -> Sentry,

	globalHub: (self: Sentry) -> Hub,
	currentHub: (self: Sentry) -> Hub,

	captureMessage: (self: Sentry, message: string) -> string,
	captureEvent: (self: Sentry, event: Event) -> string,
	captureException: (self: Sentry, exception: string) -> string,

	configureScope: (self: Sentry, (scope: Scope) -> ()) -> (),

	lastEventId: (self: Sentry) -> string?
}

export type Sentry = typeof(setmetatable({} :: {
	-- Global hub which all threads inherit from
	_main_hub: Hub,
	-- Each thread has its own hub
	_hubs: {[string]: Hub},

	transport: Transport
}, {} :: _sentry_impl))

export type _hub_impl = {
	__index: _hub_impl,
	__tostring: (self: Hub) -> string,

	new: (transport: Transport, scope: Scope?, sampleRate: number?) -> Hub,
	clone: (self: Hub) -> Hub,

	-- Returns a function that pops the scope, to help prevent stack underflow
	pushScope: (self: Hub) -> () -> (),

	captureEvent: (self: Hub, event: Event, scope: Scope) -> (),
	captureException: (self: Hub, exception: string) -> (),
	captureMessage: (self: Hub, message: string) -> (),
}

export type Hub = typeof(setmetatable({} :: {
	transport: Transport,
	sampleRate: number,
	stack: {Scope},
	_lastEventId: string?,
}, {} :: _hub_impl))

export type _scope_impl = {
	__index: _scope_impl,

	new: () -> Scope,
	clear: (self: Scope) -> (),
	clone: (self: Scope) -> Scope,

	setUser: (self: Scope, player: Player?) -> (),

	setExtra: (self: Scope, key: string, value: any?) -> (),
	setExtras: (self: Scope, extras: {[string]: any?}) -> (),

	setTag: (self: Scope, tag: string, value: any) -> (),
	setTags: (self: Scope, tags: {[string]: any}) -> (),

	setEnvironment: (self: Scope, env: string?) -> (),
	setRelease: (self: Scope, release: string?) -> (),
	setLogger: (self: Scope, logger: string?) -> (),
	setDist: (self: Scope, dist: string?) -> (),

	setContext: (self: Scope, type: 'device' | 'culture', data: DeviceContext | CultureContext) -> (),
	setFingerprint: (self: Scope, fingerprint: {string}?) -> (),
	
	setLevel: (self: Scope, level: Level) -> (),
	setTransaction: (self: Scope, name: string?) -> (),
	
	addBreadcrumb: (self: Scope, breadcrumb: Breadcrumb) -> (),
	clearBreadcrumbs: (self: Scope) -> (),

	addEventProcessor: (self: Scope, processor: EventProcessor) -> (),
	applyToEvent: (self: Scope, event: Event) -> Event?,
	__tostring: (self: Scope) -> string,
}

export type Scope = typeof(setmetatable({} :: {
	extras: {[string]: any},
	tags: {[string]: any},

	user: User?,
	breadcrumbs: {Breadcrumb}?,

	fingerprint: {string}?,
	release: string?,
	dist: string?,

	transaction: string?,
	environment: string?,
	logger: string?,

	level: Level?,
	context: {[string]: any}?,

	_eventProcessors: {EventProcessor}
}, {} :: _scope_impl))

export type _transport_impl = {
	__index: _transport_impl,

	init: (options: Options) -> Transport,
	sendEvent: (self: Transport, eventPayload: string) -> (),
}

export type DSNComponents = {
	protocol: string,
	publicKey: string, 
	url: string,
	projectId: string
}

export type Transport = typeof(setmetatable({} :: {
	dsn: DSNComponents,
	basePath: string,

	envelopeSupport: boolean,
	lastRequest: number,
	retry_after: number
}, {} :: _transport_impl))

return {Event = Event}
