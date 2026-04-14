"use strict";

const fs = require("fs/promises");
const path = require("path");
const express = require("express");
const cors = require("cors");

const PORT = Number(process.env.PORT) || 3000;
const DATA_DIR = path.join(__dirname, "data");
const DATA_FILE = path.join(DATA_DIR, "properties.json");

/** @typedef {{ id: string, title: string, address: string, description: string, price: number, status: string, isUserAdded: boolean }} Property */

/** @typedef {{ nextId: number, properties: Property[] }} PropertyStore */

function seedProperties() {
  return [
    {
      id: "p1",
      title: "Patel 3 BHK near SG Highway",
      address: "Satellite, Ahmedabad — 380015",
      description:
        "East-facing flat, modular kitchen, two balconies. Close to schools and the metro corridor.",
      price: 7850000,
      status: "forSale",
      isUserAdded: false,
    },
    {
      id: "p2",
      title: "Mehta Studio — Navrangpura",
      address: "Navrangpura, Ahmedabad — 380009",
      description:
        "Compact studio ideal for young professionals; lift, power backup, quiet lane near CEPT.",
      price: 3250000,
      status: "pending",
      isUserAdded: false,
    },
    {
      id: "p3",
      title: "Chattwal Family Bungalow, Bopal",
      address: "Bopal, Ahmedabad — 380058",
      description:
        "Four bedrooms, three baths, covered parking for two cars, small garden, gated society.",
      price: 14500000,
      status: "forSale",
      isUserAdded: false,
    },
    {
      id: "p4",
      title: "Thakkar Penthouse — Prahlad Nagar",
      address: "Prahlad Nagar, Ahmedabad — 380015",
      description:
        "Top-floor duplex with city views, clubhouse access, two dedicated parking slots.",
      price: 28200000,
      status: "sold",
      isUserAdded: false,
    },
    {
      id: "p5",
      title: "Joshi 2 BHK — Maninagar",
      address: "Maninagar, Ahmedabad — 380008",
      description:
        "Bright corner unit, recently painted; walking distance to the railway station and market.",
      price: 5650000,
      status: "forSale",
      isUserAdded: false,
    },
    {
      id: "p6",
      title: "Patel Row House, Vastrapur",
      address: "Vastrapur, Ahmedabad — 380052",
      description:
        "G+1 construction, small patio, narrow approach road; ideal for a small family.",
      price: 9350000,
      status: "pending",
      isUserAdded: false,
    },
    {
      id: "p7",
      title: "Mevada Ground-Floor 2 BHK",
      address: "Thaltej, Ahmedabad — 380054",
      description:
        "Ground floor with private sit-out; society maintenance covers common area upkeep.",
      price: 6720000,
      status: "forSale",
      isUserAdded: false,
    },
    {
      id: "p8",
      title: "Sharma Bungalow — Chandkheda",
      address: "Chandkheda, Ahmedabad — 382424",
      description:
        "Independent house; roof redone in 2023; interior ready for light renovation.",
      price: 4980000,
      status: "forSale",
      isUserAdded: false,
    },
    {
      id: "p9",
      title: "Nai Luxury 3 BHK — Bodakdev",
      address: "Bodakdev, Ahmedabad — 380054",
      description:
        "Three bedrooms, three baths, full-height windows, two covered car parks in basement.",
      price: 12800000,
      status: "sold",
      isUserAdded: false,
    },
    {
      id: "p10",
      title: "Singh Weekend Plot — Near Sanand",
      address: "Sanand–Nalsarovar Road (≈25 km from Ahmedabad)",
      description:
        "Large corner plot with bore well; weekend retreat; paperwork verified with local advocate.",
      price: 11200000,
      status: "pending",
      isUserAdded: false,
    },
  ];
}

/** @returns {PropertyStore} */
function createInitialStore() {
  return {
    nextId: 11,
    properties: seedProperties(),
  };
}

/**
 * @param {Property[]} properties
 * @returns {number}
 */
function computeNextIdFromProperties(properties) {
  let max = 10;
  for (const p of properties) {
    const m = /^p(\d+)$/.exec(p.id);
    if (m) {
      const n = Number(m[1]);
      if (Number.isFinite(n)) max = Math.max(max, n);
    }
  }
  return max + 1;
}

/** @returns {Promise<PropertyStore>} */
async function loadStore() {
  try {
    const raw = await fs.readFile(DATA_FILE, "utf8");
    const parsed = JSON.parse(raw);
    if (!parsed || !Array.isArray(parsed.properties)) {
      throw new Error("Invalid store shape");
    }
    let nextId = parsed.nextId;
    if (typeof nextId !== "number" || !Number.isFinite(nextId) || nextId < 11) {
      nextId = computeNextIdFromProperties(parsed.properties);
    }
    return { nextId, properties: parsed.properties };
  } catch (e) {
    if (e && e.code === "ENOENT") {
      const initial = createInitialStore();
      await saveStore(initial);
      return initial;
    }
    console.warn("Could not load DB file, re-seeding:", e.message);
    const initial = createInitialStore();
    await saveStore(initial);
    return initial;
  }
}

/** @param {PropertyStore} store */
async function saveStore(store) {
  await fs.mkdir(DATA_DIR, { recursive: true });
  const payload = JSON.stringify(
    { nextId: store.nextId, properties: store.properties },
    null,
    2,
  );
  await fs.writeFile(DATA_FILE, payload, "utf8");
}

/** @type {PropertyStore} */
let store = createInitialStore();

const ALLOWED_STATUS = new Set(["forSale", "sold", "pending"]);

const app = express();
app.use(cors());
app.use(express.json());

app.get("/api/health", (_req, res) => {
  res.json({ ok: true });
});

/**
 * @param {Property[]} list
 * @param {string} q lowercased trimmed needle (empty = no text filter)
 * @param {string} [status] one of ALLOWED_STATUS or empty
 */
function filterProperties(list, q, status) {
  let out = list;
  if (status && ALLOWED_STATUS.has(status)) {
    out = out.filter((p) => p.status === status);
  }
  if (q) {
    out = out.filter(
      (p) =>
        p.title.toLowerCase().includes(q) ||
        p.address.toLowerCase().includes(q) ||
        p.description.toLowerCase().includes(q),
    );
  }
  return out;
}

app.get("/api/properties", (req, res) => {
  const rawQ = req.query.q;
  const q =
    typeof rawQ === "string" && rawQ.trim() ? rawQ.trim().toLowerCase() : "";
  const rawStatus = req.query.status;
  const status =
    typeof rawStatus === "string" && rawStatus.trim() ? rawStatus.trim() : "";
  if (status && !ALLOWED_STATUS.has(status)) {
    return res.status(400).json({
      error: "Invalid status filter",
      details: ["status must be one of: forSale, sold, pending, or omitted"],
    });
  }
  const properties = filterProperties(store.properties, q, status);
  res.json({ properties });
});

app.get("/api/properties/:id", (req, res) => {
  const found = store.properties.find((p) => p.id === req.params.id);
  if (!found) {
    return res.status(404).json({ error: "Property not found" });
  }
  return res.json(found);
});

app.post("/api/properties", async (req, res) => {
  const { title, address, description, price, status } = req.body ?? {};

  const errors = [];
  if (typeof title !== "string" || title.trim().length < 3) {
    errors.push("title must be a string with at least 3 characters");
  }
  if (typeof address !== "string" || address.trim().length === 0) {
    errors.push("address is required");
  }
  if (typeof description !== "string" || description.trim().length < 10) {
    errors.push("description must be at least 10 characters");
  }
  const priceNum = typeof price === "number" ? price : Number(price);
  if (!Number.isFinite(priceNum) || priceNum <= 0) {
    errors.push("price must be a positive number");
  }
  if (typeof status !== "string" || !ALLOWED_STATUS.has(status)) {
    errors.push("status must be one of: forSale, sold, pending");
  }

  if (errors.length) {
    return res
      .status(400)
      .json({ error: "Validation failed", details: errors });
  }

  const id = `p${store.nextId++}`;
  /** @type {Property} */
  const created = {
    id,
    title: title.trim(),
    address: address.trim(),
    description: description.trim(),
    price: priceNum,
    status,
    isUserAdded: true,
  };

  store.properties.push(created);
  try {
    await saveStore(store);
  } catch (err) {
    console.error(err);
    store.properties.pop();
    store.nextId -= 1;
    return res.status(500).json({ error: "Could not persist to file" });
  }

  return res.status(201).json(created);
});

app.use((err, _req, res, _next) => {
  console.error(err);
  res.status(500).json({ error: "Internal server error" });
});

async function main() {
  store = await loadStore();
  app.listen(PORT, () => {
    console.log(`Properties API listening on http://localhost:${PORT}`);
    console.log(`  Data file: ${DATA_FILE}`);
    console.log(`  GET  http://localhost:${PORT}/api/properties?q=&status=`);
    console.log(`  POST http://localhost:${PORT}/api/properties`);
  });
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
