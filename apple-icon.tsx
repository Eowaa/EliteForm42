import { ImageResponse } from "next/og";

export const size = { width: 180, height: 180 };
export const contentType = "image/png";

export default function AppleIcon() {
  return new ImageResponse(
    (
      <div
        style={{
          width: "100%",
          height: "100%",
          display: "flex",
          alignItems: "center",
          justifyContent: "center",
          background: "#0a0a0a",
        }}
      >
        <div
          style={{
            display: "flex",
            flexDirection: "column",
            alignItems: "center",
            justifyContent: "center",
          }}
        >
          <div
            style={{
              fontSize: 48,
              fontWeight: 700,
              color: "#c9a227",
              letterSpacing: -1,
            }}
          >
            EF
          </div>
          <div
            style={{
              fontSize: 18,
              fontWeight: 600,
              color: "#e0b85a",
              marginTop: 2,
              letterSpacing: 3,
            }}
          >
            42
          </div>
        </div>
      </div>
    ),
    { ...size }
  );
}
