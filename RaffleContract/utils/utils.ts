import { ethers } from "ethers";
import RaffleManagerArtifact from "../artifacts/contracts/Raffle.sol/RaffleManager.json";

export class RaffleManagerUtils {
  public contract: ethers.Contract;

  constructor(
    providerOrSigner: ethers.Provider | ethers.Signer,
    contractAddress: string
  ) {
    this.contract = new ethers.Contract(
      contractAddress,
      RaffleManagerArtifact.abi,
      providerOrSigner
    );
  }

  async createRaffle(
    maxParticipants: number,
    deadline: number,
    nftAddress: string,
    tokenId: number
  ): Promise<ethers.ContractTransaction> {
    return await this.contract.createRaffle(
      maxParticipants,
      deadline,
      nftAddress,
      tokenId
    );
  }

  async participate(raffleId: number): Promise<ethers.ContractTransaction> {
    return await this.contract.participate(raffleId);
  }

  async triggerRaffle(raffleId: number): Promise<ethers.ContractTransaction> {
    return await this.contract.triggerRaffle(raffleId);
  }

  async getParticipants(raffleId: number): Promise<string[]> {
    return await this.contract.getParticipants(raffleId);
  }

  async getRaffle(raffleId: number): Promise<any> {
    return await this.contract.getRaffle(raffleId);
  }

  onEvent(eventName: string, callback: (...args: any[]) => void): void {
    this.contract.on(eventName, callback);
  }

  offEvent(eventName: string, callback: (...args: any[]) => void): void {
    this.contract.off(eventName, callback);
  }

  /**
   * Queries relevant events for a given raffleId and returns a JSON object with raffle details and stats.
   */
  async getRaffleStats(raffleId: number): Promise<any> {
    const raffleCreatedFilter = this.contract.filters.RaffleCreated(raffleId);
    const raffleCreatedEvents = await this.contract.queryFilter(raffleCreatedFilter);
    if (raffleCreatedEvents.length === 0) {
      throw new Error(`No raffle found for raffleId ${raffleId}`);
    }
    const createdArgs = (raffleCreatedEvents[0] as ethers.EventLog).args;

    const participatedFilter = this.contract.filters.Participated(raffleId);
    const participatedEvents = await this.contract.queryFilter(participatedFilter);
    const participants = participatedEvents.map((event) => (event as ethers.EventLog).args?.participant);

    const triggeredFilter = this.contract.filters.RaffleTriggered(raffleId);
    const triggeredEvents = await this.contract.queryFilter(triggeredFilter);
    let triggered = false;
    let winner = null;
    let randomIndex = null;
    if (triggeredEvents.length > 0) {
      triggered = true;
      const triggeredArgs = (triggeredEvents[0] as ethers.EventLog).args;
      winner = triggeredArgs.winner;
      randomIndex = triggeredArgs.randomIndex;
    }

    return {
      raffleId,
      organizer: createdArgs.organizer,
      maxParticipants: createdArgs.maxParticipants.toString(),
      deadline: createdArgs.deadline.toString(),
      nftAddress: createdArgs.nftAddress,
      tokenId: createdArgs.tokenId.toString(),
      requestId: createdArgs.requestId.toString(),
      participants,
      totalParticipants: participants.length,
      triggered,
      winner,
      randomIndex: randomIndex !== null ? randomIndex.toString() : null,
    };
  }

  /**
   * Returns a list of raffles the user participated in.
   * Each object contains the raffleId, organizer, and a boolean indicating if the user won.
   */
  async getUserParticipatedRaffles(
    userAddress: string
  ): Promise<{ raffleId: number; organizer: string; won: boolean }[]> {
    const participatedFilter = this.contract.filters.Participated(null, userAddress);
    const participatedEvents = await this.contract.queryFilter(participatedFilter);

    const raffleIdsSet = new Set<number>();
    for (const event of participatedEvents) {
      raffleIdsSet.add((event as ethers.EventLog).args?.raffleId.toNumber());
    }

    const results: { raffleId: number; organizer: string; won: boolean }[] = [];
    for (const raffleId of Array.from(raffleIdsSet)) {
      try {
        const stats = await this.getRaffleStats(raffleId);
        const won = stats.triggered && (stats.winner.toLowerCase() === userAddress.toLowerCase());
        results.push({
          raffleId,
          organizer: stats.organizer,
          won,
        });
      } catch (error) {
        console.error(`Error fetching stats for raffle ${raffleId}:`, error);
      }
    }
    return results;
  }
}

export function getProvider(rpcUrl: string): ethers.JsonRpcProvider {
  return new ethers.JsonRpcProvider(rpcUrl);
}
