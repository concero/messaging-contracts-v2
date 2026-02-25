import type { Duration, DurationJson } from "@bufbuild/protobuf/wkt";
import {
	CacheSettings,
	CacheSettingsJson,
} from "@chainlink/cre-sdk/dist/generated/capabilities/networking/http/v1alpha/client_pb";

export const headers = { "Content-Type": "application/json" };

export const getDuration = (seconds: bigint): Duration => {
	return { $typeName: "google.protobuf.Duration", seconds, nanos: 0 };
};

export const timeout: Duration = getDuration(10n);

export const timeoutJson: DurationJson = "10s";

export const cacheSettings: CacheSettings = {
	$typeName: "capabilities.networking.http.v1alpha.CacheSettings",
	store: true,
	maxAge: getDuration(5n),
};

export const cacheSettingsJson: CacheSettingsJson = {
	store: true,
	maxAge: "10s",
};

export const defaultMinConfirmations = 1n;

export const defaultGetLogsBlockDepth = 1000n;
