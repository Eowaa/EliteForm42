import { ImageResponse } from "next/og";

export const size = { width: 512, height: 512 };
export const contentType = "image/png";

export default function Icon() {
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
          borderRadius: 96,
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
              fontSize: 72,
              fontWeight: 700,
              color: "#c9a227",
              letterSpacing: -2,
            }}
          >
            EF
          </div>
          <div
            style={{
              fontSize: 28,
              fontWeight: 600,
              color: "#e0b85a",
              marginTop: 4,
              letterSpacing: 4,
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
