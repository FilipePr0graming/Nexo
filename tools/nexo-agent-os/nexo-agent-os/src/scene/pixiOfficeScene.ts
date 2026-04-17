import * as PIXI from "pixi.js";

import type { Agent } from "../agents/types";
import type { AgentVisualState } from "../events/types";
import { gridToWorldX, gridToWorldY, TILE_SIZE, GRID_HEIGHT, GRID_WIDTH } from "./constants";

type SceneAssets = {
  container: PIXI.Container;
  world: PIXI.Container;
  agentsLayer: PIXI.Container;
  hudLayer: PIXI.Container;

  agentSprites: Map<string, PIXI.Container>;
  agentLabels: Map<string, PIXI.Text>;
};

export function createOfficeScene(app: PIXI.Application): SceneAssets {
  const container = new PIXI.Container();
  const world = new PIXI.Container();
  const agentsLayer = new PIXI.Container();
  const hudLayer = new PIXI.Container();

  container.addChild(world);
  container.addChild(agentsLayer);
  container.addChild(hudLayer);

  // Floor grid
  const floor = new PIXI.Graphics();
  floor.beginFill(0x0b1220);
  floor.drawRoundedRect(0, 0, gridToWorldX(GRID_WIDTH) - 16, gridToWorldY(GRID_HEIGHT) - 16, 18);
  floor.endFill();

  const grid = new PIXI.Graphics();
  grid.lineStyle(1, 0x17223a, 0.9);
  for (let x = 0; x <= GRID_WIDTH; x++) {
    const px = gridToWorldX(x) - 16;
    grid.moveTo(px, gridToWorldY(0) - 16);
    grid.lineTo(px, gridToWorldY(GRID_HEIGHT) - 16);
  }
  for (let y = 0; y <= GRID_HEIGHT; y++) {
    const py = gridToWorldY(y) - 16;
    grid.moveTo(gridToWorldX(0) - 16, py);
    grid.lineTo(gridToWorldX(GRID_WIDTH) - 16, py);
  }

  world.addChild(floor);
  world.addChild(grid);

  // Desks + chairs (simple pixel-like)
  const furniture = new PIXI.Graphics();
  function desk(x: number, y: number, tint: number) {
    const wx = gridToWorldX(x);
    const wy = gridToWorldY(y);
    furniture.beginFill(tint);
    furniture.drawRoundedRect(wx - 14, wy - 10, 44, 22, 6);
    furniture.endFill();

    furniture.beginFill(0x1b2b4a);
    furniture.drawRoundedRect(wx - 6, wy + 16, 22, 16, 6);
    furniture.endFill();
  }

  desk(7, 5, 0x123d46); // dev
  desk(11, 5, 0x1b2a5a); // backend
  desk(15, 5, 0x3d2c10); // qa
  desk(19, 5, 0x1b3b23); // finance

  // QA area
  furniture.beginFill(0x2a1f3f);
  furniture.drawRoundedRect(gridToWorldX(14) - 16, gridToWorldY(9) - 16, 6 * TILE_SIZE, 3 * TILE_SIZE, 14);
  furniture.endFill();

  world.addChild(furniture);

  const agentSprites = new Map<string, PIXI.Container>();
  const agentLabels = new Map<string, PIXI.Text>();

  // Root container for agents is agentsLayer

  app.stage.addChild(container);

  return {
    container,
    world,
    agentsLayer,
    hudLayer,
    agentSprites,
    agentLabels,
  };
}

export function upsertAgentSprites(
  scene: SceneAssets,
  agents: Agent[],
  opts: {
    fontFamily?: string;
  } = {}
) {
  const fontFamily = opts.fontFamily ?? "system-ui";

  for (const agent of agents) {
    let sprite = scene.agentSprites.get(agent.id);
    let label = scene.agentLabels.get(agent.id);

    if (!sprite) {
      sprite = new PIXI.Container();

      const body = new PIXI.Graphics();
      // body base (pixel-ish)
      body.beginFill(0x94a3b8);
      body.drawRoundedRect(-10, -16, 20, 22, 6);
      body.endFill();

      const head = new PIXI.Graphics();
      head.beginFill(0xe2e8f0);
      head.drawRoundedRect(-9, -30, 18, 16, 6);
      head.endFill();

      const visor = new PIXI.Graphics();
      visor.beginFill(0x0f172a);
      visor.drawRoundedRect(-6, -25, 12, 6, 3);
      visor.endFill();

      sprite.addChild(head);
      sprite.addChild(visor);
      sprite.addChild(body);

      label = new PIXI.Text({
        text: agent.name,
        style: {
          fontFamily,
          fontSize: 12,
          fill: 0xe2e8f0,
          fontWeight: "600",
        },
      });
      label.anchor.set(0.5, 0);
      label.y = 10;

      sprite.addChild(label);

      scene.agentsLayer.addChild(sprite);
      scene.agentSprites.set(agent.id, sprite);
      scene.agentLabels.set(agent.id, label);
    }

    sprite.x = gridToWorldX(agent.x);
    sprite.y = gridToWorldY(agent.y);

    applyStateTint(sprite, agent.state);

    // Update text
    if (label) {
      label.text = agent.name;
    }
  }
}

function applyStateTint(container: PIXI.Container, state: AgentVisualState) {
  // Tint the body (child 2) and head (child 0) for quick visual feedback
  const head = container.children[0] as PIXI.Graphics | undefined;
  const body = container.children[2] as PIXI.Graphics | undefined;

  const [headColor, bodyColor] = (() => {
    switch (state) {
      case "typing":
        return [0xe2e8f0, 0x22c55e];
      case "testing":
        return [0xe2e8f0, 0x3b82f6];
      case "reading":
        return [0xe2e8f0, 0xeab308];
      case "walking":
        return [0xe2e8f0, 0x64748b];
      case "error":
        return [0xe2e8f0, 0xef4444];
      default:
        return [0xe2e8f0, 0x94a3b8];
    }
  })();

  // Pixi Graphics tint is not directly supported for fill changes, so we re-draw.
  if (head) {
    head.clear();
    head.beginFill(headColor);
    head.drawRoundedRect(-9, -30, 18, 16, 6);
    head.endFill();
  }

  if (body) {
    body.clear();
    body.beginFill(bodyColor);
    body.drawRoundedRect(-10, -16, 20, 22, 6);
    body.endFill();
  }
}
