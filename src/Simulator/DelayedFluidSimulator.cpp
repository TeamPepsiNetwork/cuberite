
// DelayedFluidSimulator.cpp

// Interfaces to the cDelayedFluidSimulator class representing a fluid simulator that has a configurable delay
// before simulating a block. Each tick it takes a consecutive delay "slot" and simulates only blocks in that slot.

#include "Globals.h"

#include "DelayedFluidSimulator.h"
#include "../World.h"
#include "../Chunk.h"





////////////////////////////////////////////////////////////////////////////////
// cDelayedFluidSimulatorChunkData::cSlot

bool cDelayedFluidSimulatorChunkData::cSlot::Add(int a_RelX, int a_RelY, int a_RelZ)
{
	ASSERT(a_RelZ >= 0);
	ASSERT(a_RelZ < static_cast<int>(ARRAYCOUNT(m_Blocks)));

	cCoordWithBiIntVector & Blocks = m_Blocks[a_RelZ];
	int Index = cChunkDef::MakeIndexNoCheck(a_RelX, a_RelY, a_RelZ);
	for (cCoordWithBiIntVector::const_iterator itr = Blocks.begin(), end = Blocks.end(); itr != end; ++itr)
	{
		if (itr->Data == Index)
		{
			//reset cooldown because we need to
			itr->other = -2147483648;
			// Already present
			return false;
		}
	}  // for itr - Blocks[]
	Blocks.push_back(cCoordWithBiInt(a_RelX, a_RelY, a_RelZ, Index, -2147483648));
	return true;
}





////////////////////////////////////////////////////////////////////////////////
// cDelayedFluidSimulatorChunkData:

cDelayedFluidSimulatorChunkData::cDelayedFluidSimulatorChunkData(int a_TickDelay)// :
	//m_Slots(new cSlot[a_TickDelay])
{
}





cDelayedFluidSimulatorChunkData::~cDelayedFluidSimulatorChunkData()
{
	//delete[] m_Slots;
	//m_Slots = nullptr;
}





////////////////////////////////////////////////////////////////////////////////
// cDelayedFluidSimulator:

cDelayedFluidSimulator::cDelayedFluidSimulator(cWorld & a_World, BLOCKTYPE a_Fluid, BLOCKTYPE a_StationaryFluid, int a_TickDelay) :
	super(a_World, a_Fluid, a_StationaryFluid),
	m_TickDelay(a_TickDelay),
	//m_AddSlotNum(a_TickDelay - 1),
	//m_SimSlotNum(0),
	m_TotalBlocks(0)
{
}





void cDelayedFluidSimulator::AddBlock(Vector3i a_Block, cChunk * a_Chunk)
{
	if ((a_Block.y < 0) || (a_Block.y >= cChunkDef::Height))
	{
		// Not inside the world (may happen when rclk with a full bucket - the client sends Y = -1)
		return;
	}

	if ((a_Chunk == nullptr) || !a_Chunk->IsValid())
	{
		return;
	}

	int RelX = a_Block.x - a_Chunk->GetPosX() * cChunkDef::Width;
	int RelZ = a_Block.z - a_Chunk->GetPosZ() * cChunkDef::Width;
	BLOCKTYPE BlockType = a_Chunk->GetBlock(RelX, a_Block.y, RelZ);
	if (BlockType != m_FluidBlock)
	{
		return;
	}

	auto ChunkDataRaw = (m_FluidBlock == E_BLOCK_WATER) ? a_Chunk->GetWaterSimulatorData() : a_Chunk->GetLavaSimulatorData();
	cDelayedFluidSimulatorChunkData * ChunkData = static_cast<cDelayedFluidSimulatorChunkData *>(ChunkDataRaw);
	cDelayedFluidSimulatorChunkData::cSlot & Slot = ChunkData->m_Slot;

	// Add, if not already present:
	if (!Slot.Add(RelX, a_Block.y, RelZ))
	{
		return;
	}

	++m_TotalBlocks;
}





void cDelayedFluidSimulator::Simulate(float a_Dt)
{
	//m_AddSlotNum = m_SimSlotNum;
	//m_SimSlotNum += 1;
	//if (true || m_SimSlotNum >= m_TickDelay)
	//{
	//	m_SimSlotNum = 0;
	//}
}





void cDelayedFluidSimulator::SimulateChunk(std::chrono::milliseconds a_Dt, int a_ChunkX, int a_ChunkZ, cChunk * a_Chunk)
{
	auto ChunkDataRaw = (m_FluidBlock == E_BLOCK_WATER) ? a_Chunk->GetWaterSimulatorData() : a_Chunk->GetLavaSimulatorData();
	cDelayedFluidSimulatorChunkData * ChunkData = static_cast<cDelayedFluidSimulatorChunkData *>(ChunkDataRaw);
	cDelayedFluidSimulatorChunkData::cSlot & Slot = ChunkData->m_Slot;

    int time = a_Dt.count() / 50;
    // Simulate all the blocks in the scheduled slot:
    for (size_t i = 0; i < ARRAYCOUNT(Slot.m_Blocks); i++) {
        cCoordWithBiIntVector &Blocks = Slot.m_Blocks[i];
        if (Blocks.empty()) {
            continue;
        }

        //this is a saga of why i hate c++
        //and only a few of the attempts i had here are commented out, most got deleted again
        //took me the better part of a day
        //heck
        // -- daporkchop_

        /*std::remove_if(Blocks.begin(), Blocks.end(), [=](cCoordWithBiInt& itr){
            LOG("Delta: %d, current: %d, delay: %d", time, itr.other, m_TickDelay);
            if (itr.other + time >= m_TickDelay) {
                SimulateBlock(a_Chunk, itr.x, itr.y, itr.z);
                m_TotalBlocks--;
                return true;
            } else {
                itr.other += time;
                return false;
            }
        });*/
        for (cCoordWithBiInt& e_ : Blocks)   {
            cCoordWithBiInt* e = &e_;
            if (e->other == -2147483648)   {
                e->other = 0;
            }
        }
        /*int j = Blocks.size() - 1;
        for (auto itr = Blocks.begin(); j >= 0; j--)  {
            auto e = itr + j;
        }*/

        for (auto itr = Blocks.begin(), end = Blocks.end(); itr != end; itr++)  {
            int other = itr->other;
            LOGD("Delta: %d, current: %d, delay: %d", time, other, m_TickDelay);
            if (other >= 0 && (itr->other = other + time) >= m_TickDelay)    {
                itr->other = -1;
                SimulateBlock(a_Chunk, itr->x, itr->y, itr->z);
                LOGD("Simulated!");
            }
        }

        for (auto itr = Blocks.begin(); itr != Blocks.end();)  {
            bool flag = itr->other == -1;
            if (flag)   {
                LOGD("Removing...");
                itr = Blocks.erase(itr);
            } else {
                itr++;
            }
        }
        /*std::remove_if(Blocks.begin(), Blocks.end(), [=](const cCoordWithBiInt & val){
            if (flag)   {
                LOG("Removing...");
            }
            return flag;
        });*/

        /*
        auto itr = Blocks.begin();
        while (itr != Blocks.end()) {
            int other = itr->other;
            LOG("Delta: %d, current: %d, delay: %d", time, other, m_TickDelay);
            if (other != -1 && other + time >= m_TickDelay) {
                LOG("Simulating...");
                SimulateBlock(a_Chunk, itr->x, itr->y, itr->z);
                LOG("Erasing...");
                itr = Blocks.erase(itr);
                LOG("Decrementing...");
                m_TotalBlocks--;
                LOG("Done!");
            } else {
                itr->other = other + time;
                itr++;
            }
        }*/
        //m_TotalBlocks -= static_cast<int>(Blocks.size());
        //Blocks.clear();
    }
}




