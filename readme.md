
# WiseBuddhiClub - Korea

이 스마트 컨트랙트는 OG와 WL과 같은 다른 접근 수준을 가진 ERC-1155 NFT를 발행합니다.

## 컨트랙트 변수

- `_name` - NFT 컬렉션의 이름
- `_symbol` - NFT 컬렉션의 상징
- `_totalSupply` - 발행된 NFT의 총 수량
- `WBC_OG` - OG NFT의 토큰 ID
- `WBC_WL` - WL NFT의 토큰 ID
- `uriPrefix` - 토큰 URI의 기본 URI
- `uriSuffix` - 토큰 URI에 추가할 접미사
- `hiddenMetadataUri` - 공개 전 사용할 URI
- `OGPrice` - OG NFT 발행 가격
- `WLPrice` - WL NFT 발행 가격
- `publicPrice` - 일반 발행 가격
- `maxSupply` - NFT 최대 공급량
- `OGSupply` - OG NFT 최대 공급량
- `WLSupply` - WL NFT 최대 공급량  
- `totalOGMinted` - 발행된 OG NFT 수
- `totalWLMinted` - 발행된 WL NFT 수
- `maxMintAmountPerTx` - 트랜잭션 당 최대 NFT 수 
- `maxMintAmountPerAddress` - 주소 당 최대 NFT 수
- `mintedAmount` - 주소 당 발행한 NFT 수
- `revealed` - 메타데이터 공개 여부
- `pause` - 발행 일시정지 여부
- `round` - 현재 발행 라운드

## 발행 함수

- `whitelistMint` - WL 라운드에서 WL NFT 발행
- `OGMint` - OG 라운드에서 OG NFT 발행
- `mint` - 일반 발행

## 소유자 함수

- `mintOGIdentifier` - OG 패스 발행
- `mintWLIdentifier` - WL 패스 발행
- `distributeOGIdentifier` - OG 패스 배포
- `distributeWLIdentifier` - WL 패스 배포
- `airdropNFT` - NFT 에어드롭
- `setRevealed` - 메타데이터 공개
- `moveRound` - 다음 발행 라운드로 이동
- `setPaused` - 발행 일시정지/재개
- `setPublicPrice` - 일반 발행 가격 설정
- `setOGPrice` - OG 발행 가격 설정
- `setWLPrice` - WL 발행 가격 설정
- `setWLSupply` - WL 최대 공급량 설정
- `setOGSupply` - OG 최대 공급량 설정
- `setMaxMintAmountPerTx` - 트랜잭션 당 최대 발행량 설정
- `setMaxMintAmountPerAddress` - 주소 당 최대 발행량 설정
- `setHiddenMetadataUri` - 숨겨진 메타데이터 URI 설정
- `setURI` - 기본 URI 설정
- `setUriPrefix` - URI 접두사 설정
- `setUriSuffix` - URI 접미사 설정
- `withdraw` - 자금 인출

## 조회 함수

- `name` - 이름 조회
- `symbol` - 상징 조회 
- `totalSupply` - 총 공급량 조회
- `getRoundStatus` - 현재 라운드 조회
- `tokenURI` - 토큰 URI 조회
- `isUserOG` - 사용자가 OG NFT 보유 여부 확인
- `isUserWL` - 사용자가 WL NFT 보유 여부 확인
- `getOGBalance` - 사용자 OG 보유 수량 조회
- `getWLBalance` - 사용자 WL 보유 수량 조회

웹사이트는 config 폴더 내의 info.json 파일을 사용하여 설정됩니다. 사이트의 컨텐츠를 업데이트하기 위해서는 이 파일만 편집하시면 됩니다. 각 필드는 다음과 같습니다:

"contract_address": 배포된 NFT 스마트 컨트랙트 주소를 입력하세요. "contract_address" 부분은 수정하지 마시고, 주소만 따옴표 안에 붙여넣기 하세요.

"chainId": 블록체인 네트워크를 지정합니다. 1은 이더리움 메인넷을 의미합니다.

"links": 사이트에 표시할 링크를 입력하세요. 각 속성의 따옴표 사이에 URL을 붙여넣기 하시면 됩니다.

"opensea": 오픈시에서 컬렉션 링크
"twitter": 트위터 페이지 링크
"discord": 디스코드 초대 링크
"website": 외부 사이트 링크가 있다면 입력하세요.
"description": 홈페이지에 표시할 프로젝트 설명을 입력하세요. 따옴표 사이에 텍스트를 작성하거나 붙여넣기 하세요.

이 스마트 계약의 인출 기능이 현재 개발자에게 팁으로 초기 판매의 5%를 보내도록 프로그래밍되어 있음을 참고하시기 바랍니다. 이는 계약 생성 노력에 대한 개발자 지원 방식으로 수행되었습니다.

하지만 이 팁 메커니즘이 편하지 않다면, 저는 완전히 이해합니다. 계약 소유자로서, 당신은 기능에 대한 전적 재량권이 있습니다. 5% 팁을 제거하도록 인출 기능을 수정하고 싶다면 알려주세요. 인출된 자금 100%가 직접 귀하의 계좌로 가도록 코드를 기쁘게 업데이트하겠습니다.

당신의 기본 설정을 알려주시면 필요한 변경 사항을 기쁘게 하겠습니다. 귀하의 목표와 기본 설정에 부합하는 스마트 계약을 만드는 것이 저의 목표입니다. 추가 피드백도 언제든지 주십시오 - 이 계약이 귀하의 요구를 가장 잘 충족하도록 하기 위해 여기 있습니다.


# WiseBuddhiClub - En

This is an ERC-1155 NFT contract that mints NFTs with different access levels - OG and WL. 

## Contract Variables

- `_name` - Name of the NFT collection
- `_symbol` - Symbol of the NFT collection 
- `_totalSupply` - Total supply of NFTs minted
- `WBC_OG` - Token ID for OG NFTs 
- `WBC_WL` - Token ID for WL NFTs
- `uriPrefix` - Base URI for token URIs
- `uriSuffix` - Suffix to add to token URIs 
- `hiddenMetadataUri` - URI to use before reveal
- `OGPrice` - Mint price for OG NFTs
- `WLPrice` - Mint price for WL NFTs  
- `publicPrice` - Mint price for public sale
- `maxSupply` - Max supply of NFTs
- `OGSupply` - Max supply of OG NFTs
- `WLSupply` - Max supply of WL NFTs
- `totalOGMinted` - Total OG NFTs minted
- `totalWLMinted` - Total WL NFTs minted
- `maxMintAmountPerTx` - Max NFTs per transaction
- `maxMintAmountPerAddress` - Max NFTs per address
- `mintedAmount` - Number of NFTs minted per address
- `revealed` - Whether metadata is revealed
- `pause` - Whether minting is paused
- `round` - Current minting round 

## Minting Functions

- `whitelistMint` - Mint WL NFTs during WL round
- `OGMint` - Mint OG NFTs during OG round
- `mint` - Public mint

## Owner Functions 

- `mintOGIdentifier` - Mint OG passes
- `mintWLIdentifier` - Mint WL passes
- `distributeOGIdentifier` - Distribute OG passes
- `distributeWLIdentifier` - Distribute WL passes  
- `airdropNFT` - Airdrop NFTs
- `setRevealed` - Reveal metadata
- `moveRound` - Move to next minting round
- `setPaused` - Pause/unpause minting
- `setPublicPrice` - Set public mint price
- `setOGPrice` - Set OG mint price
- `setWLPrice` - Set WL mint price
- `setWLSupply` - Set max WL supply
- `setOGSupply` - Set max OG supply
- `setMaxMintAmountPerTx` - Set max mint per TX
- `setMaxMintAmountPerAddress` - Set max mint per address
- `setHiddenMetadataUri` - Set hidden metadata URI
- `setURI` - Set base URI
- `setUriPrefix` - Set URI prefix
- `setUriSuffix` - Set URI suffix
- `withdraw` - Withdraw funds

## View Functions

- `name` - Get name
- `symbol` - Get symbol
- `totalSupply` - Get total supply  
- `getRoundStatus` - Get current round
- `tokenURI` - Get token URI
- `isUserOG` - Check if user has OG NFT
- `isUserWL` - Check if user has WL NFT
- `getOGBalance` - Get user's OG balance
- `getWLBalance` - Get user's WL balance

The website is configured using the info.json file located in the dist folder. This is the only file you need to edit to update content on the site. Here's what each field represents:

- "contract_address": This is where you'll put the address of the deployed NFT smart contract. Don't change the "contract_address" part, just paste the address inside the quotes.

- "chainId": This specifies the blockchain network. 1 is for Ethereum mainnet. 

- "links": This contains links you want to display on the site. Just paste in the URL between the quotes for each property.

  - "opensea": Link to the collection on OpenSea

  - "twitter": Link to the Twitter page

  - "discord": Invite link for Discord

  - "website": Link to an external site if you have one

- "description": This is where you can put a description of the project that will appear on the home page. Just write or paste text between the quotes. 


Please note that the withdraw function in this smart contract is currently programmed to send 5% of the initial sales as a tip to the developer. This was done as a way to support the developer for their efforts in creating the contract.

However, if you are not comfortable with this tip mechanism, I completely understand. As the contract owner, you have full discretion over its functionality. Please let me know if you would like me to modify the withdraw function to remove the 5% tip. I'm happy to update the code so that 100% of the withdrawn funds will go directly to your address.

Just let me know your preference and I'll be glad to make the necessary changes. I aim to create a smart contract that aligns with your goals and preferences. Feel free to provide any other feedback as well - I'm here to ensure this contract best serves your needs.
