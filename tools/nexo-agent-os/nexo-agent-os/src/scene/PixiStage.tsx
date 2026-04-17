import { useEffect, useMemo, useRef } from "react";
import * as PIXI from "pixi.js";

import type { Agent } from "../agents/types";
import { createOfficeScene, upsertAgentSprites } from "./pixiOfficeScene";
import { GRID_HEIGHT, GRID_WIDTH, TILE_SIZE, SCENE_PADDING } from "./constants";

export function PixiStage(props: { agents: Agent[] }) {
  const hostRef = useRef<HTMLDivElement | null>(null);
  const appRef = useRef<PIXI.Application | null>(null);
  const sceneRef = useRef<ReturnType<typeof createOfficeScene> | null>(null);

  const width = useMemo(() => GRID_WIDTH * TILE_SIZE + SCENE_PADDING * 2, []);
  const height = useMemo(() => GRID_HEIGHT * TILE_SIZE + SCENE_PADDING * 2, []);

  useEffect(() => {
    if (!hostRef.current) return;

    const app = new PIXI.Application();
    appRef.current = app;

    let destroyed = false;

    (async () => {
      await app.init({
        width,
        height,
        backgroundColor: 0x0f172a,
        antialias: false,
        resolution: window.devicePixelRatio || 1,
        autoDensity: true,
      });

      if (destroyed) return;

      hostRef.current!.appendChild(app.canvas);
      const scene = createOfficeScene(app);
      sceneRef.current = scene;

      upsertAgentSprites(scene, props.agents);
    })();

    return () => {
      destroyed = true;
      sceneRef.current = null;
      appRef.current?.destroy(true);
      appRef.current = null;
      hostRef.current?.replaceChildren();
    };
  }, [height, width]);

  useEffect(() => {
    const scene = sceneRef.current;
    if (!scene) return;

    upsertAgentSprites(scene, props.agents);
  }, [props.agents]);

  return (
    <div
      ref={hostRef}
      style={{
        flex: 1,
        display: "flex",
        alignItems: "center",
        justifyContent: "center",
        background: "#0f172a",
      }}
    />
  );
}
