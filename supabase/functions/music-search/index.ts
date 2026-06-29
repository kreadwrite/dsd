type Track = {
  id: string;
  title: string;
  artist: string;
  genre?: string;
  duration?: number;
  streamURL: string;
  imageURL?: string;
  externalURL?: string;
  lyrics?: string;
};

const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), {
    status,
    headers: {
      "content-type": "application/json",
      "access-control-allow-origin": "*",
    },
  });

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return json({});

  const url = new URL(req.url);
  const provider = url.searchParams.get("provider") ?? "";
  const q = (url.searchParams.get("q") ?? "").trim();
  if (!q) return json({ tracks: [] });

  if (provider === "audius") {
    return json({ tracks: await searchAudius(q) });
  }

  if (provider === "soundcloud") {
    return json({ tracks: await searchSoundCloud(q) });
  }

  return json({ tracks: [] });
});

async function searchAudius(q: string): Promise<Track[]> {
  const host = Deno.env.get("AUDIUS_DISCOVERY_HOST") ?? "https://discoveryprovider.audius.co";
  const appName = Deno.env.get("AUDIUS_APP_NAME") ?? "Aura";
  const endpoint = `${host}/v1/tracks/search?query=${encodeURIComponent(q)}&app_name=${encodeURIComponent(appName)}&limit=20`;
  const response = await fetch(endpoint);
  if (!response.ok) return [];
  const payload = await response.json();
  return (payload.data ?? [])
    .map((item: any) => mapAudius(item, host, appName))
    .filter((track: Track | null): track is Track => track !== null);
}

function mapAudius(item: any, host: string, appName: string): Track | null {
  const id = String(item.id ?? "");
  const streamURL = id
    ? `${host}/v1/tracks/${encodeURIComponent(id)}/stream?app_name=${encodeURIComponent(appName)}`
    : undefined;
  if (!streamURL) return null;
  return {
    id,
    title: item.title ?? "Untitled",
    artist: item.user?.name ?? "Audius",
    genre: item.genre,
    duration: item.duration,
    streamURL,
    imageURL: item.artwork?.["480x480"] ?? item.artwork?.["150x150"],
    externalURL: item.permalink,
  };
}

async function searchSoundCloud(q: string): Promise<Track[]> {
  const clientID = Deno.env.get("SOUNDCLOUD_CLIENT_ID");
  if (!clientID) return [];
  const endpoint = `https://api-v2.soundcloud.com/search/tracks?q=${encodeURIComponent(q)}&client_id=${clientID}&limit=20`;
  const response = await fetch(endpoint);
  if (!response.ok) return [];
  const payload = await response.json();
  const mapped = await Promise.all(
    (payload.collection ?? []).map((item: any) => mapSoundCloud(item, clientID)),
  );
  return mapped.filter((track: Track | null): track is Track => track !== null);
}

async function mapSoundCloud(item: any, clientID: string): Promise<Track | null> {
  const transcodingURL = item.media?.transcodings?.find((entry: any) =>
    String(entry.format?.protocol ?? "").includes("progressive")
  )?.url ?? item.media?.transcodings?.[0]?.url;
  const streamURL = transcodingURL ? await resolveSoundCloudStream(transcodingURL, clientID) : undefined;
  if (!streamURL) return null;
  return {
    id: String(item.id),
    title: item.title ?? "Untitled",
    artist: item.user?.username ?? "SoundCloud",
    genre: item.genre,
    duration: Math.round((item.duration ?? 0) / 1000),
    streamURL,
    imageURL: item.artwork_url,
    externalURL: item.permalink_url,
  };
}

async function resolveSoundCloudStream(transcodingURL: string, clientID: string): Promise<string | undefined> {
  const separator = transcodingURL.includes("?") ? "&" : "?";
  const response = await fetch(`${transcodingURL}${separator}client_id=${clientID}`);
  if (!response.ok) return undefined;
  const payload = await response.json();
  return payload.url;
}
