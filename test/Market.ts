import { expect } from 'chai';
import { ethers } from 'hardhat';

describe('Market', function () {
  let market: any;
  let signer1: any;
  let signer2: any;
  let signer3: any;
  let address1: any;
  let address2: any;
  let address3: any;

  beforeEach(async function () {
    const Market = await ethers.getContractFactory('Market');
    const marketplace = await Market.deploy();
    await marketplace.deployed();

    market = marketplace;

    const [owner, user1, user2, user3] = await ethers.getSigners();

    signer1 = user1;
    signer2 = user2;
    signer3 = user3;

    address1 = await signer1.getAddress();
    address2 = await signer2.getAddress();
    address3 = await signer3.getAddress();

    await market.grantRole(ethers.utils.id('MINTER_ROLE'), address1);
  });

  it.skip('Should have correct roles assigned', async function () {
    const hasRole1 = await market.hasRole(ethers.utils.id('MINTER_ROLE'), address1);
    const hasRole2 = await market.hasRole(ethers.utils.id('MINTER_ROLE'), address2);

    expect(hasRole1).to.be.true;
    expect(hasRole2).to.be.false;
  });

  it.skip('Should mint token to contract address', async function () {
    const minted1 = await market.safeMint(address1, '1', ethers.utils.parseEther('0.005'));
    await minted1.wait();

    const ownerOf = await market.ownerOf(0);

    expect(ownerOf).to.equal(address1);
    expect(ownerOf).to.not.equal(address2);

    const minted2 = await market.safeMint(address1, '2', ethers.utils.parseEther('0.006'));
    await minted2.wait();

    const balance = await market.balanceOf(address1);

    expect(balance).to.equal(2);

    const minted3 = await market.safeMint(address2, '3', ethers.utils.parseEther('0.007'));
    await minted3.wait();

    const marketConnected = market.connect(signer1);

    const minted4 = await marketConnected.safeMint(address2, '4', ethers.utils.parseEther('0.008'));
    await minted4.wait();

    const allEntities = await market.entitiesAll();

    console.log(allEntities);
  });

  it('Should return all entities for sale', async function () {
    const marketWithSigner1 = market.connect(signer1);

    const minted1 = await marketWithSigner1.safeMint('1', ethers.utils.parseEther('0.001'));
    await minted1.wait();

    console.log(await market.entitiesForSale());
  });

  it.skip('Should sell', async function () {
    const marketWithSigner1 = market.connect(signer1);

    const minted1 = await marketWithSigner1.safeMint('1', ethers.utils.parseEther('0.001'));
    await minted1.wait();

    const ownerOf1 = await market.ownerOf(0);

    expect(ownerOf1).to.equal(address1);

    const marketWithSigner2 = market.connect(signer2);

    await marketWithSigner2.buy(0, { value: ethers.utils.parseEther('0.001') });

    const ownerOf2 = await market.ownerOf(0);

    expect(ownerOf2).to.equal(address2);

    await marketWithSigner2.list(ethers.utils.parseEther('0.002'), 0);

    const marketWithSigner3 = market.connect(signer3);

    await marketWithSigner3.buy(0, { value: ethers.utils.parseEther('0.002') });

    const ownerOf3 = await market.ownerOf(0);

    expect(ownerOf3).to.equal(address3);
  });

  it.skip("Should do something, I don't know", async function () {
    const minted3 = await market.safeMint(address2, '3');
    await minted3.wait();

    const minted4 = await market.safeMint(address1, '4');
    await minted4.wait();

    const balance = await market.balanceOf(address1);

    expect(balance).to.equal(3);

    const keys = [...Array(balance.toNumber()).keys()];

    const tokens = await Promise.all(
      keys.map(async key => (await market.tokenOfOwnerByIndex(address1, key)).toNumber())
    );

    const tokenURIs = await Promise.all(tokens.map(async token => await market.tokenURI(token)));

    expect(tokenURIs).to.have.members([
      'https://nft.xyz/ipfs/1',
      'https://nft.xyz/ipfs/2',
      'https://nft.xyz/ipfs/4',
    ]);

    const allEntities = await market.entitiesAll();

    console.log(allEntities);
  });
});
