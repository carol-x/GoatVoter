import { ConnectButton } from '@rainbow-me/rainbowkit';
import type { NextPage } from 'next';
import Head from 'next/head';
import styles from '../styles/Home.module.css';
import { useAccount } from 'wagmi';
import { useState, useEffect, useRef, useLayoutEffect } from 'react';
import {
  Flex, Avatar, Text, Box, VStack, Kbd, Link, Accordion, AccordionItem, AccordionButton,
  AccordionPanel, AccordionIcon, Spacer, RadioGroup, Stack, Radio, Button, Center, Progress
} from '@chakra-ui/react'
import { ExternalLinkIcon } from '@chakra-ui/icons'

import { getMaker, getCompound, getAll } from '../resources/getProposals'

const Home: NextPage = () => {
  //see if wallet is connected
  const { isConnected } = useAccount()

  //width of progress bar
  const ref = useRef<any>(null);
  const width = 80
  const [barW, setBarW] = useState(0);

  useLayoutEffect(() => {
    setBarW(ref.current.offsetWidth * 0.4);
  }, []);

  //get date progress bar length
  function barLength(start: Date, end: Date) {
    var today = new Date();
    var startDate = new Date(start)
    var endDate = new Date(end)

    const s = startDate.getTime()
    const e = endDate.getTime()
    const c = today.getTime()

    return 100 * (c - s) / (e - s)
  }

  //create function to generate DAO icon
  function getIcon(platform: String) {
    let link
    switch (platform) {
      case "Aave":
        link = "https://cryptologos.cc/logos/aave-aave-logo.png"
        break
      case "Uniswap":
        link = "https://upload.wikimedia.org/wikipedia/commons/thumb/e/e7/Uniswap_Logo.svg/1026px-Uniswap_Logo.svg.png"
        break
      case "Compound":
        link = "https://cryptologos.cc/logos/compound-comp-logo.png"
        break
      case "Maker":
        link = "https://seeklogo.com/images/M/maker-mkr-logo-FAA728D102-seeklogo.com.png"
        break
    }
    return link
  }

  //get proposals on page load
  const [proposals, setProposals] = useState<any>({})
  const [isLoading, setLoading] = useState(false)
  // useEffect(() => {
  //   setLoading(true)
  //   fetch('https://proposal-api.vercel.app/api/proposal')
  //     .then((res) => res.json())
  //     .then((data) => {
  //       getMaker()
  //       setProposals(data.proposals)
  //       setLoading(false)
  //     })
  // }, [])
  useEffect(() => {
    setLoading(true)
    getAll()
      .then((data) => {
        setProposals(data)
        setLoading(false)
        console.log(proposals)
      })
  }, [])

  if (isLoading) return <p>Loading...</p>
  if (!proposals) return <p>No Active Proposals!</p>

  return (
    <div className={styles.container}>
      <Head>
        <title>GoatVote</title>
        <meta
          name="description"
          content="Generated by @rainbow-me/create-rainbowkit"
        />
        <link rel="icon" href="/favicon.ico" />
      </Head>
      <main className={styles.main}>
        <ConnectButton />
        <Box width={width + "%"} ref={ref}>
          {
            proposals.map((key: any, index: any) => <h1>Hello! {proposals[key].title}</h1>)
          }
          <Accordion allowMultiple>
            <AccordionItem>
              <h2>
                <AccordionButton>
                  <Box flex='1' textAlign='left'>
                    MakerDAO
                  </Box>
                  <AccordionIcon />
                </AccordionButton>

              </h2>
              <AccordionPanel>
                <VStack align='stretch'>
                  {
                    proposals
                      .map(prop =>
                        <Flex key={prop.id}>
                          <Center>
                            <Avatar src={getIcon(prop.platform)} />
                            <Box ml='3' key={prop.id}>
                              {/* <Text fontWeight='bold'>
                              {prop.platform} - <Kbd><Link href={prop.pollForum} isExternal>See More<ExternalLinkIcon mx='2px' /></Link></Kbd>
                            </Text> */}
                              <Text fontWeight='bold'>{prop.title} <Kbd><Link href={prop.link} isExternal><ExternalLinkIcon mx='2px' /></Link></Kbd></Text>
                              <Progress width={barW} value={barLength(prop.startDate, prop.endDate)} />
                              <Text>Member Votes: Yes: {0}, No: {0}</Text>
                            </Box>
                          </Center>
                          <Spacer />
                          <Center>
                            <Flex>
                              <RadioGroup>
                                <Stack spacing={5} direction='row'>
                                  <Radio colorScheme='green' value='1' isChecked>
                                    Yay
                                  </Radio>
                                  <Radio colorScheme='red' value='2'>
                                    Nay
                                  </Radio>
                                  <Button colorScheme='green' size='xs'>
                                    Submit
                                  </Button>
                                </Stack>
                              </RadioGroup>
                            </Flex>
                          </Center>
                        </Flex>

                      )
                  }
                </VStack>
              </AccordionPanel>
            </AccordionItem>
          </Accordion>
        </Box>
      </main>

    </div>
  );
};

export default Home;
