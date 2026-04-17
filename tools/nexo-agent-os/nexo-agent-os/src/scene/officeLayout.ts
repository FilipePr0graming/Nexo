export type OfficeSpotId =
  | "dev_desk"
  | "backend_desk"
  | "qa_desk"
  | "finance_desk"
  | "qa_area";

export type OfficeSpot = {
  id: OfficeSpotId;
  label: string;
  x: number;
  y: number;
};

export const officeSpots: Record<OfficeSpotId, OfficeSpot> = {
  dev_desk: { id: "dev_desk", label: "Frontend", x: 7, y: 5 },
  backend_desk: { id: "backend_desk", label: "Backend", x: 11, y: 5 },
  qa_desk: { id: "qa_desk", label: "QA", x: 15, y: 5 },
  finance_desk: { id: "finance_desk", label: "Financeiro", x: 19, y: 5 },
  qa_area: { id: "qa_area", label: "Testes", x: 15, y: 9 },
};
