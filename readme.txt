Christina Hurley email to Peets on 02/23/23

Chris and Jeff:
 
A team of us have been working within the datasets in Snowflake (Aloha Enterprise, Paytronix and Shopify). 
We have found a gap where we need some assistance from the Peet’s team. 
First the good news – we are able to tie what we are seeing in our inquiries back to Power BI when we seek to tie data in aggregate.
Brian and Matt have done a several tests to confirm that. 
The challenge we are having is tying “Is Loyalty” checks back to an account.
With the data we have, we need to be able to tie the account to a check – and when we do that, we are tying a fair number of checks back to the OLO store – as the check number with all of the “loyalty details” is tied to that OLO-generated number.  We know that the “OLO store” is really a holding store of sorts, and that these checks then are distributed to the correct location (brick and mortar) to complete the order.  We also know that when this happens an Aloha check is generated within the POS.  The issue is that we need to be able to tie the OLO Check Number to the corresponding Aloha check number so that we can link the loyalty details to the POS check within a location.  
Because Power BI is handling this properly – the reporting there checks out. 
We know that there is likely some additional logic/code/check mapping that is going on behind the scenes. 
We need to apply this same logic to the Snowflake data so that we can do the same correct mapping. 
I’m directing this request to you both in the hope that one of you will be able to help us with this check attachment.
Jeff, second request for you.  
I have not seen the Ticket for the Listrak export (one-time export).
I’m not sure if it exists, and I was not added to it (completely fine, but could you add me so that I have visibility to the progress.). 
 
Feeling like we are on the 10-yard line – with the goal clearly in sight!
 
Best,
CH
 
Christina Hurley
Director, Loyalty & CRM
Hathway/Bounteous
Christina.hurley@bounteous.com
c: 617-548-2759
 
www.bounteous.com 


Christina Hurley Notes on Peets 02/28/23

I wanted to give you some detail and information to share with Jeff (and potentially) Allan on the CDP progress.
The bad news is -- we are not as far along as we had hoped we would be in "using" the CDP information.
The good new is -- in working the way we have, we had uncovered data gaps that will need to be closed so that the CDP can be used in the way the Peet's intends, and this is important.
We have not yet established a "Golden Record" -- and there are 2 reasons for this.  The First is in making the connection between the PX data and the Aloha data, we are missing a logic step that helps connect an "OLO initiated" check to its corresponding Aloha check.  There was a lengthy email sent to Jeff and Chris explaining this gap and that it was a blocker to making progress.   We know that Peet's has already developed code to address this because their Power BI instance is properly reporting.  That same logic needs to be brought over into the CDP   so that we can connect a loyalty account to a check. (Without this information we are vastly under-counting loyalty activity).
The second issue is the lack of the Listrak information in the CDP -- we know this is/was a Peet's decision.  They know that the Listrak database will need some scrubbing prior to moving to Iterable.  And thus was excluded.  We understand that plan -- but to gain an assessment of a true golden record, we need to see which email addresses live in both data sets (as the Ecommerce team leverage the Listrak database).   While not perfect -- when we raised the issue to Peet's, there was a thought that we could do a one-time "static export" of the Listrak DB.  This would be better than the total absence of information.
One of the goals of the CDP is to leverage the data to message to members (in the broadest sense) based on how they are engaging with the Peet's brand.  And using that data to create the most relevant and targeted messaging (to drive incrementality).
Without closing these two gaps -- 1) we are not able to complete the work we set out to complete in the SOW and 2) it's likely that Peet's will also run into the same issues as they take ownership of the management of the CDP.
