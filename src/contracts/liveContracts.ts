export type UserId = string
export type LiveRoomId = string

export type CohostSignalEvent =
  | 'cohost-request'
  | 'cohost-accept'
  | 'cohost-decline'
  | 'cohost-active'
  | 'cohost-peer-list'
  | 'cohost-offer'
  | 'cohost-answer'
  | 'cohost-ice-source'
  | 'cohost-ice-target'
  | 'cohost-ended'
  | 'cohost-source-left'
  | 'cohost-failed'

export interface LiveActorIdentity {
  actorId: UserId
  displayName: string
  avatarUrl?: string | null
  gifterLevel: number
}

export interface GiftActivityPayload extends LiveActorIdentity {
  roomId: LiveRoomId
  giftId: string
  quantity: number
  coinsSpent: number
}

export interface CohostPeerIdentity extends LiveActorIdentity {
  viewerId: string
}

export interface CohostSignalPayload {
  roomId: LiveRoomId
  sourceViewerId?: string
  targetViewerId?: string
  sourceUserId?: UserId
  targetUserId?: UserId
}

export interface LiveTapBatchPayload {
  roomId: LiveRoomId
  batchId: string
  timestamps: number[]
}

export function isValidGiftQuantity(quantity: number): boolean {
  return Number.isSafeInteger(quantity) && quantity > 0 && quantity <= 1000
}
