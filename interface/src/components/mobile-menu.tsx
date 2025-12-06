'use client';

import { useState } from 'react';
import {
  Drawer,
  DrawerTrigger,
  DrawerContent,
 
  DrawerClose,
} from '@/components/ui/drawer';
import { Menu } from 'lucide-react';

import BlockchainDropdown from './dropdown/block-chain-dropdown';
import { Button } from './ui/button';

export default function MobileMenu() {
  const [open, setOpen] = useState(false);

  return (
    <Drawer open={open} onOpenChange={setOpen}>
      <DrawerTrigger asChild>
        <Button
          variant="outline"
          size="icon"
          className="sm:hidden  bg-red-600 bg-transparent border-none text-white"
        >
            <Menu className="!w-[8vw] !h-[8vw] text-white" />
        </Button>
      </DrawerTrigger>

      <DrawerContent className="bg-black text-white border-t border-gray-700">
      

        <div className="flex items-center justify-center gap-4 px-6 pb-4 pt-0">
          <BlockchainDropdown />
          
        </div>

        <DrawerClose asChild>
          <Button variant="outline" className="mx-6 mb-4 border-gray-600">
            Close
          </Button>
        </DrawerClose>
      </DrawerContent>
    </Drawer>
  );
}
